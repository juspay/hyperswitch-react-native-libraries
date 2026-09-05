
open ReactNative

type assetTable = {
  visa: Image.Source.t,
  mastercard: Image.Source.t,
  americanexpress: Image.Source.t,
  dinersclub: Image.Source.t,
  discover: Image.Source.t,
  jcb: Image.Source.t,
  cartesbancaires: Image.Source.t,
  interac: Image.Source.t,
  waitcard: Image.Source.t,
  cvv: Image.Source.t,
  camera: Image.Source.t,
}

@module("./cardIconAssets.mjs") external assets: assetTable = "cardIconAssets"

type detectedScheme =
  | Visa
  | Mastercard
  | AmericanExpress
  | DinersClub
  | Discover
  | JCB
  | CartesBancaires
  | Interac
  | RuPay
  | UnionPay
  | Maestro
  | Bajaj
  | Sodexo
  | Unrecognised

let fromDetectedName = (name: string): detectedScheme =>
  switch name->String.trim->String.toLowerCase {
  | "visa" => Visa
  | "mastercard" => Mastercard
  | "americanexpress" => AmericanExpress
  | "dinersclub" => DinersClub
  | "discover" => Discover
  | "jcb" => JCB
  | "cartesbancaires" => CartesBancaires
  | "interac" => Interac
  | "rupay" => RuPay
  | "unionpay" => UnionPay
  | "maestro" => Maestro
  | "bajaj" => Bajaj
  | "sodexo" => Sodexo
  | _ => Unrecognised
  }

let artworkFor = (scheme: detectedScheme): Image.Source.t =>
  switch scheme {
  | Visa => assets.visa
  | Mastercard => assets.mastercard
  | AmericanExpress => assets.americanexpress
  | DinersClub => assets.dinersclub
  | Discover => assets.discover
  | JCB => assets.jcb
  | CartesBancaires => assets.cartesbancaires
  | Interac => assets.interac

  | RuPay
  | UnionPay
  | Maestro
  | Bajaj
  | Sodexo
  | Unrecognised =>
    assets.waitcard
  }

@genType
type brandIconMode = [#standard | #animated | #hidden | #hideGeneric]

let placeholderCycle = ["visa", "mastercard", "americanexpress", "dinersclub", "discover", "jcb"]

@react.component
let make = (~detectedScheme: string, ~size: float=30., ~mode: brandIconMode=#standard) => {
  let hasBrand = detectedScheme->String.trim->String.length > 0

  let fadeAnim = CardAnimatedValue.useAnimatedValue(1.)
  let scaleAnim = fadeAnim->Animated.Value.interpolate({
    inputRange: [0., 1.],
    outputRange: [0.8, 1.]->Animated.Interpolation.fromFloatArray,
    extrapolate: #clamp,
  })

  let ((_, placeholder), setPlaceholder) = React.useState(_ => (
    0,
    mode === #animated ? "visa" : "waitcard",
  ))

  let animationRef = React.useRef(None)

  let rec startContinuousAnimation = () => {
    let fadeOutSequence = Animated.sequence([
      Animated.delay(2000.),
      Animated.timing(
        fadeAnim,
        {
          toValue: 0.->Animated.Value.Timing.fromRawValue,
          duration: 300.,
          useNativeDriver: true,
          easing: Easing.ease,
        },
      ),
    ])

    animationRef.current = Some(fadeOutSequence)

    fadeOutSequence->Animated.start(~endCallback=endResult =>
      if endResult.finished {
        setPlaceholder(((index, _)) => {
          let newIndex = index === 5 ? 0 : index + 1
          (newIndex, placeholderCycle->Array.get(newIndex)->Option.getOr("waitcard"))
        })

        let fadeInAnimation = Animated.timing(
          fadeAnim,
          {
            toValue: 1.->Animated.Value.Timing.fromRawValue,
            duration: 300.,
            useNativeDriver: true,
            easing: Easing.ease,
          },
        )
        animationRef.current = Some(fadeInAnimation)
        fadeInAnimation->Animated.start(~endCallback=endResult =>
          if endResult.finished {
            startContinuousAnimation()
          }
        )
      }
    )
  }

  let stopAnimation = () =>
    switch animationRef.current {
    | Some(animation) => animation->Animated.stop
    | None => ()
    }

  React.useLayoutEffect2(() => {
    if mode === #animated && !hasBrand {
      startContinuousAnimation()
      Some(() => stopAnimation())
    } else {
      stopAnimation()
      fadeAnim->Animated.Value.setValue(1.)
      None
    }
  }, (detectedScheme, (mode :> string)))

  React.useEffect0(() => Some(() => stopAnimation()))

  let visible = switch mode {
  | #hidden => false
  | #hideGeneric => hasBrand
  | #standard | #animated => true
  }

  let iconName = hasBrand ? detectedScheme : placeholder

  visible
    ? <Animated.View
        style={Style.s({
          opacity: fadeAnim->Animated.StyleProp.float,
          transform: [Style.scale(~scale=scaleAnim->Animated.StyleProp.float)],
        })}>
        <Image
          source={iconName->fromDetectedName->artworkFor}
          resizeMode=#contain
          style={Style.s({width: size->Style.dp, height: size->Style.dp})}
          accessible=false
        />
      </Animated.View>
    : React.null
}

/*
 * The scan-card glyph — client-core's `Icon.res` camera path, rasterised black and TINTED here, so
 * it takes the merchant's colour exactly as `fill=primaryColor` did there. `tintColor` on a
 * monochrome PNG is what lets one asset serve every theme without shipping a variant per colour.
 */
module Camera = {
  @react.component
  let make = (~size: float=20., ~color: string) =>
    <Image
      source={assets.camera}
      resizeMode=#contain
      tintColor=color
      style={Style.s({width: size->Style.dp, height: size->Style.dp})}
      accessible=false
    />
}

module Cvc = {
  @react.component
  let make = (~size: float=32.) =>
    <Image
      source={assets.cvv}
      resizeMode=#contain
      style={Style.s({width: size->Style.dp, height: size->Style.dp})}
      accessible=false
    />
}
