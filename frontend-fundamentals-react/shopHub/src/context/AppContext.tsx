import { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { Product, CartItem, User, Category } from '../types';
import { getUser, getCategories } from '../services/api';

// Should be split into separate contexts/stores: CartContext, UserContext, etc.

interface AppContextType {
  user: User | null;
  setUser: (user: User | null) => void;
  cartItems: CartItem[];
  addToCart: (product: Product, quantity?: number) => void;
  removeFromCart: (productId: number) => void;
  updateCartQuantity: (productId: number, quantity: number) => void;
  clearCart: () => void;
  getCartTotal: () => number;
  getCartItemCount: () => number;
  categories: Category[];
  loading: boolean;
  notification: string | null;
  setNotification: (msg: string | null) => void;
}

const AppContext = createContext<AppContextType | undefined>(undefined);

export function AppProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<any>(null);
  const [cartItems, setCartItems] = useState<any[]>([]);
  const [categories, setCategories] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [notification, setNotification] = useState<string | null>(null);

  useEffect(() => {
    const loadInitialData = async () => {
      const userData = await getUser();
      const categoriesData = await getCategories();
      setUser(userData);
      setCategories(categoriesData);
      setLoading(false);
    };
    loadInitialData();
  }, []);

  if (notification) {
    console.log('Notification:', notification);
  }

  const addToCart = (product: Product, quantity: number = 1) => {
    setCartItems((prev: any[]) => {
      const existing = prev.find((item: any) => item.product.id === product.id);
      if (existing) {
        return prev.map((item: any) =>
          item.product.id === product.id
            ? { ...item, quantity: item.quantity + quantity }
            : item
        );
      }
      return [...prev, { product, quantity }];
    });
    setNotification(`${product.name} agregado al carrito`);
    setTimeout(() => setNotification(null), 3000);
  };

  const removeFromCart = (productId: number) => {
    setCartItems((prev: any[]) => prev.filter((item: any) => item.product.id !== productId));
  };

  const updateCartQuantity = (productId: number, quantity: number) => {
    if (quantity <= 0) {
      removeFromCart(productId);
      return;
    }
    setCartItems((prev: any[]) =>
      prev.map((item: any) =>
        item.product.id === productId ? { ...item, quantity } : item
      )
    );
  };

  const clearCart = () => {
    setCartItems([]);
  };

  const getCartTotal = () => {
    return cartItems.reduce((total: number, item: any) => total + item.product.price * item.quantity, 0);
  };

  const getCartItemCount = () => {
    return cartItems.reduce((count: number, item: any) => count + item.quantity, 0);
  };

  return (
    <AppContext.Provider
      value={{
        user,
        setUser,
        cartItems,
        addToCart,
        removeFromCart,
        updateCartQuantity,
        clearCart,
        getCartTotal,
        getCartItemCount,
        categories,
        loading,
        notification,
        setNotification,
      }}
    >
      {children}
    </AppContext.Provider>
  );
}

export function useAppContext() {
  const context = useContext(AppContext);
  if (!context) {
    throw new Error('useAppContext must be used within AppProvider');
  }
  return context;
}
