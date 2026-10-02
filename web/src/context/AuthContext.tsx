import React, {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useState,
} from 'react';
import { fetchDevTokens, type DevPersona } from '../api/client';

interface AuthState {
  token: string | null;
  persona: (DevPersona & { id: string }) | null;
  personas: Record<string, DevPersona> | null;
  loading: boolean;
  error: string | null;
  login: (personaId: string) => void;
  logout: () => void;
}

const AuthContext = createContext<AuthState | null>(null);

const STORAGE_TOKEN = 'ql_token';
const STORAGE_PERSONA = 'ql_persona';

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [token, setToken] = useState<string | null>(
    () => localStorage.getItem(STORAGE_TOKEN),
  );
  const [persona, setPersona] = useState<(DevPersona & { id: string }) | null>(
    () => {
      const raw = localStorage.getItem(STORAGE_PERSONA);
      return raw ? JSON.parse(raw) : null;
    },
  );
  const [personas, setPersonas] = useState<Record<string, DevPersona> | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetchDevTokens()
      .then((data) => {
        setPersonas(data);
        setLoading(false);
      })
      .catch((e: Error) => {
        setError(e.message);
        setLoading(false);
      });
  }, []);

  const login = useCallback(
    (personaId: string) => {
      if (!personas) return;
      const p = personas[personaId];
      if (!p) return;
      const full = { ...p, id: personaId };
      setToken(p.token);
      setPersona(full);
      localStorage.setItem(STORAGE_TOKEN, p.token);
      localStorage.setItem(STORAGE_PERSONA, JSON.stringify(full));
    },
    [personas],
  );

  const logout = useCallback(() => {
    setToken(null);
    setPersona(null);
    localStorage.removeItem(STORAGE_TOKEN);
    localStorage.removeItem(STORAGE_PERSONA);
  }, []);

  return (
    <AuthContext.Provider value={{ token, persona, personas, loading, error, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth(): AuthState {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used inside AuthProvider');
  return ctx;
}
