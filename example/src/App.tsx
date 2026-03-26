import { useState } from 'react';
import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';
import {
  HyperInit,
} from '@juspay-tech/react-native-hyperswitch';
import UIScreen from './UIScreen';
import HeadlessScreen from './HeadlessScreen';

type TabType = 'ui' | 'headless';

export default function App() {
  const [activeTab, setActiveTab] = useState<TabType>('ui');
  
  const publishableKey = process.env.HYPERSWITCH_PUBLISHABLE_KEY;
  const profileId = process.env.PROFILE_ID;

  const hyperPromise =
    publishableKey && profileId ?
      HyperInit(publishableKey, profileId)
    : null;

  if (!publishableKey || !profileId) {
    return (
      <View style={styles.centerContainer}>
        <Text>Configure env and restart Metro server</Text>
        <Text style={styles.subText}>
          HYPERSWITCH_PUBLISHABLE_KEY and PROFILE_ID required
        </Text>
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
          <Text style={[styles.tabText, activeTab === 'ui' && styles.activeTabText]}>
            UI Mode
          </Text>
        </TouchableOpacity>
        <TouchableOpacity 
          style={[styles.tab, activeTab === 'headless' && styles.activeTab]}
          onPress={() => setActiveTab('headless')}
        >
          <Text style={[styles.tabText, activeTab === 'headless' && styles.activeTabText]}>
            Headless Mode
          </Text>
        </TouchableOpacity>
      </View>
      
      <View style={styles.content}>
        {activeTab === 'ui' ? (
          <UIScreen hyperPromise={hyperPromise} />
        ) : (
          <HeadlessScreen hyperPromise={hyperPromise} />
        )}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  centerContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  subText: {
    fontSize: 12,
    color: '#666',
    marginTop: 8,
  },
  tabContainer: {
    flexDirection: 'row',
    backgroundColor: '#f5f5f5',
    paddingTop: 50,
    borderBottomWidth: 1,
    borderBottomColor: '#ddd',
  },
  tab: {
    flex: 1,
    paddingVertical: 16,
    alignItems: 'center',
  },
  activeTab: {
    backgroundColor: '#fff',
    borderBottomWidth: 2,
    borderBottomColor: '#007AFF',
  },
  tabText: {
    fontSize: 16,
    color: '#666',
    fontWeight: '500',
  },
  activeTabText: {
    color: '#007AFF',
    fontWeight: '600',
  },
  content: {
    flex: 1,
  },
});
