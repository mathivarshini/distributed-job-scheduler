import { createContext, useContext, useMemo, useState } from 'react';

interface AppContextValue {
  isAuthenticated: boolean;
  setIsAuthenticated: (value: boolean) => void;
}

const AppContext = createContext<AppContextValue | undefined>(undefined);

export function AppProvider({ children }: { children: React.ReactNode }) {
  const [isAuthenticated, setIsAuthenticated] = useState(false);

  const value = useMemo(() => ({ isAuthenticated, setIsAuthenticated }), [isAuthenticated]);

  return <AppContext.Provider value={value}>{children}</AppContext.Provider>;
}

export function useAppContext() {
  const context = useContext(AppContext);
  if (!context) {
    throw new Error('useAppContext must be used within AppProvider');
  }
  return context;
}
