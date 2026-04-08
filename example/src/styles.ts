import { StyleSheet } from 'react-native';

export const styles = StyleSheet.create({
  container: {
    flexGrow: 1,
    alignItems: 'center',
    padding: 24,
    gap: 16,
    paddingTop: 16,
    paddingBottom: 40,
  },
  scrollContainer: {
    flexGrow: 1,
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    marginBottom: 16,
    color: '#333',
  },
  textInput: {
    borderColor: 'gray',
    borderWidth: 1,
    borderRadius: 36,
    fontSize: 24,
    paddingHorizontal: 20,
    width: '100%',
    backgroundColor: 'white',
  },
  button: {
    width: '100%',
    height: 48,
    backgroundColor: '#1D4ED8',
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 36,
  },
  buttonDisabled: {
    backgroundColor: '#9CA3AF',
  },
  confirmButton: {
    backgroundColor: '#059669',
  },
  buttonText: {
    fontSize: 18,
    color: 'white',
  },
  status: {
    marginVertical: 32,
    gap: 12,
  },
  statusText: {
    fontSize: 24,
    color: 'blue',
    textAlign: 'center',
  },
  messageText: {
    fontSize: 18,
    color: 'blue',
    textAlign: 'center',
  },
  methodCard: {
    width: '100%',
    backgroundColor: '#F3F4F6',
    padding: 16,
    borderRadius: 12,
    marginVertical: 8,
    borderWidth: 1,
    borderColor: '#E5E7EB',
  },
  methodLabel: {
    fontSize: 14,
    fontWeight: 'bold',
    color: '#6B7280',
    marginBottom: 8,
    textTransform: 'uppercase',
  },
  methodText: {
    fontSize: 16,
    color: '#374151',
    marginBottom: 4,
  },
  defaultBadge: {
    fontSize: 12,
    fontWeight: 'bold',
    color: '#059669',
    marginTop: 8,
  },
  loader: {
    marginVertical: 16,
  },
});
