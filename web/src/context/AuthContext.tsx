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
  loginByRole: (role: 'OFFICER' | 'DESK' | 'ADMIN', loginId?: string, password?: string) => Promise<boolean>;
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

  const loginByRole = useCallback(
    async (role: 'OFFICER' | 'DESK' | 'ADMIN', loginId?: string, _password?: string): Promise<boolean> => {
      let pool = personas;
      if (!pool) {
        try {
          pool = await fetchDevTokens();
          setPersonas(pool);
        } catch (e: any) {
          setError(e.message);
          return false;
        }
      }

      const cleanId = (loginId || '').trim().toLowerCase();

      // 1. Exact or partial key match in available personas
      let targetKey: string | undefined;
      let targetPersona: DevPersona | undefined;

      if (cleanId) {
        // Try exact key
        for (const [k, p] of Object.entries(pool)) {
          if (k.toLowerCase() === cleanId && p.role === role) {
            targetKey = k;
            targetPersona = p;
            break;
          }
        }
      }

      // 2. Fallback to any persona with the specified role
      if (!targetPersona) {
        for (const [k, p] of Object.entries(pool)) {
          if (p.role === role) {
            targetKey = k;
            targetPersona = p;
            break;
          }
        }
      }

      if (targetKey && targetPersona) {
        const full = { ...targetPersona, id: targetKey };
        setToken(targetPersona.token);
        setPersona(full);
        localStorage.setItem(STORAGE_TOKEN, targetPersona.token);
        localStorage.setItem(STORAGE_PERSONA, JSON.stringify(full));
        return true;
      }

      return false;
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
    <AuthContext.Provider value={{ token, persona, personas, loading, error, login, loginByRole, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth(): AuthState {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used inside AuthProvider');
  return ctx;
}
