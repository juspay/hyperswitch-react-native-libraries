import { useState } from 'react';
import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';
import { HyperInit } from '@juspay-tech/react-native-hyperswitch';
import UIScreen from './UIScreen';
import HeadlessScreen from './HeadlessScreen';
import PaymentScreenWithHook from './PaymentScreen';
import CVCScreen from './CVCScreen';

type TabType = 'ui' | 'cvc' | 'headless';

export default function App() {
  const [activeTab, setActiveTab] = useState<TabType>('ui');

  const publishableKey = process.env.HYPERSWITCH_PUBLISHABLE_KEY;
  const profileId = process.env.PROFILE_ID;

  const hyperPromise =
    publishableKey && profileId ? HyperInit(publishableKey, profileId) : null;

  if (!publishableKey || !profileId) {
    return (
      <View style={styles.centerContainer}>
        <Text>Configure env and restart Metro server</Text>
      </View>
    );
  }

  if (!hyperPromise) {
    return (
      <View style={styles.centerContainer}>
        <Text>Initializing...</Text>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <View style={styles.tabContainer}>
        <TouchableOpacity
          style={[styles.tab, activeTab === 'ui' && styles.activeTab]}
          onPress={() => setActiveTab('ui')}
        >
          <Text
            style={[styles.tabText, activeTab === 'ui' && styles.activeTabText]}
          >
            UI Mode
          </Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={[styles.tab, activeTab === 'cvc' && styles.activeTab]}
          onPress={() => setActiveTab('cvc')}
        >
          <Text
            style={[
              styles.tabText,
              activeTab === 'cvc' && styles.activeTabText,
            ]}
          >
            CVC Widget
          </Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={[styles.tab, activeTab === 'headless' && styles.activeTab]}
          onPress={() => setActiveTab('headless')}
        >
          <Text
            style={[
              styles.tabText,
              activeTab === 'headless' && styles.activeTabText,
            ]}
          >
            Headless Mode
          </Text>
        </TouchableOpacity>
      </View>

      <View style={styles.content}>
        {activeTab === 'ui' && (
          <PaymentScreenWithHook hyperPromise={hyperPromise} />
        )}
        {activeTab === 'cvc' && <CVCScreen hyperPromise={hyperPromise} />}
        {activeTab === 'headless' && (
          <HeadlessScreen hyperPromise={hyperPromise} />
        )}
      </View>
    </View>
  );
}

// Midnight Glow Color Palette - Lumina Glass Design System
// const MIDNIGHT_ABYSS = '#020C1B';
// const DEEP_COBALT = '#0F3460';
// const LUMINOUS_INDIGO = '#5E5CE6';
// const CYBER_GLOW = '#5E5CE6';
// const GLASS_SURFACE = 'rgba(255, 255, 255, 0.07)';
// const TEXT_PRIMARY = '#FFFFFF';
// const TEXT_SECONDARY = 'rgba(255, 255, 255, 0.7)';

const styles = StyleSheet.create({
  container: {
    flex: 1,
    // backgroundColor: MIDNIGHT_ABYSS,
  },
  centerContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    // backgroundColor: MIDNIGHT_ABYSS,
  },
  tabContainer: {
    flexDirection: 'row',
    // backgroundColor: GLASS_SURFACE,
    backgroundColor: '#f5f5f5',
    paddingTop: 50,
    borderBottomWidth: 1,
    // borderBottomColor: DEEP_COBALT,
    borderBottomColor: '#ddd',
  },
  tab: {
    flex: 1,
    paddingVertical: 16,
    alignItems: 'center',
  },
  activeTab: {
    // backgroundColor: DEEP_COBALT,
    // borderBottomWidth: 2,
    // borderBottomColor: LUMINOUS_INDIGO,
    backgroundColor: '#fff',
    borderBottomWidth: 2,
    borderBottomColor: '#007AFF',
  },
  tabText: {
    fontSize: 16,
    color: '#666',
    fontWeight: '500',
    // color: TEXT_SECONDARY,
    // fontWeight: '500',
    // fontFamily: 'Manrope',
  },
  activeTabText: {
    color: '#007AFF',
    fontWeight: '600',
    // color: LUMINOUS_INDIGO,
    // fontWeight: '600',
    // fontFamily: 'Manrope',
  },
  content: {
    flex: 1,
    marginTop: 8,
    // backgroundColor: MIDNIGHT_ABYSS,
  },
});
