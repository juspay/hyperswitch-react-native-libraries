export interface Colors {
  primary?: string;
  background?: string;
  componentBackground?: string;
  componentBorder?: string;
  componentDivider?: string;
  componentText?: string;
  primaryText?: string;
  secondaryText?: string;
  placeholderText?: string;
  icon?: string;
  error?: string;
  loaderBackground?: string;
  loaderForeground?: string;
  overlay?: string;
  selectedComponentBackground?: string;
  selectedComponentBorder?: string;
  selectedComponentBorderWidth?: number;
  selectedComponentDivider?: string;
  selectedComponentText?: string;
}

export interface ColorType {
  light?: Colors;
  dark?: Colors;
}

export interface OffsetType {
  x?: number;
  y?: number;
}

export interface ShadowConfig {
  color?: string;
  opacity?: number;
  blurRadius?: number;
  offset?: OffsetType;
  intensity?: number;
}

export interface Shapes {
  borderRadius?: number;
  borderWidth?: number;
  shadow?: ShadowConfig;
  inputHeight?: number;
  gap?: number;
}

export interface Font {
  family?: string;
  scale?: number;
  headingTextSizeAdjust?: number;
  subHeadingTextSizeAdjust?: number;
  placeholderTextSizeAdjust?: number;
  buttonTextSizeAdjust?: number;
  errorTextSizeAdjust?: number;
  linkTextSizeAdjust?: number;
  modalTextSizeAdjust?: number;
  cardTextSizeAdjust?: number;
}
