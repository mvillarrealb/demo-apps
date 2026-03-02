import { Product, Category, User, Order } from '../types';

export const categories: Category[] = [
  { id: 1, name: 'Electrónica', description: 'Dispositivos electrónicos y gadgets', image: 'https://placehold.co/300x200/3b82f6/white?text=Electronica' },
  { id: 2, name: 'Ropa', description: 'Moda y vestimenta para toda la familia', image: 'https://placehold.co/300x200/ec4899/white?text=Ropa' },
  { id: 3, name: 'Hogar', description: 'Artículos para el hogar y decoración', image: 'https://placehold.co/300x200/22c55e/white?text=Hogar' },
  { id: 4, name: 'Deportes', description: 'Equipamiento y ropa deportiva', image: 'https://placehold.co/300x200/f59e0b/white?text=Deportes' },
  { id: 5, name: 'Libros', description: 'Libros, ebooks y material de lectura', image: 'https://placehold.co/300x200/8b5cf6/white?text=Libros' },
];

export const products: Product[] = [
  // Electrónica (categoryId: 1)
  { id: 1, name: 'Smartphone Pro Max', description: 'Teléfono inteligente de última generación con cámara triple y pantalla AMOLED de 6.7 pulgadas', price: 999.99, image: 'https://placehold.co/300x300/3b82f6/white?text=Smartphone', categoryId: 1, stock: 25, rating: 4.5 },
  { id: 2, name: 'Laptop UltraBook 15"', description: 'Notebook ultradelgada con procesador de última generación y 16GB RAM', price: 1299.99, image: 'https://placehold.co/300x300/3b82f6/white?text=Laptop', categoryId: 1, stock: 15, rating: 4.7 },
  { id: 3, name: 'Auriculares Bluetooth', description: 'Auriculares inalámbricos con cancelación de ruido activa y batería de 30h', price: 199.99, image: 'https://placehold.co/300x300/3b82f6/white?text=Auriculares', categoryId: 1, stock: 50, rating: 4.3 },
  { id: 4, name: 'Tablet 10"', description: 'Tablet con pantalla retina y lápiz digital incluido para creativos', price: 599.99, image: 'https://placehold.co/300x300/3b82f6/white?text=Tablet', categoryId: 1, stock: 30, rating: 4.4 },
  { id: 5, name: 'Smartwatch Deportivo', description: 'Reloj inteligente con GPS integrado y monitor cardíaco avanzado', price: 299.99, image: 'https://placehold.co/300x300/3b82f6/white?text=Smartwatch', categoryId: 1, stock: 40, rating: 4.2 },
  { id: 6, name: 'Cámara Mirrorless 4K', description: 'Cámara sin espejo profesional con grabación de video 4K 60fps', price: 849.99, image: 'https://placehold.co/300x300/3b82f6/white?text=Camara', categoryId: 1, stock: 10, rating: 4.8 },

  // Ropa (categoryId: 2)
  { id: 7, name: 'Camiseta Premium', description: 'Camiseta de algodón orgánico con diseño exclusivo y corte moderno', price: 29.99, image: 'https://placehold.co/300x300/ec4899/white?text=Camiseta', categoryId: 2, stock: 100, rating: 4.1 },
  { id: 8, name: 'Jeans Slim Fit', description: 'Pantalón vaquero de corte ajustado con elastano para mayor comodidad', price: 59.99, image: 'https://placehold.co/300x300/ec4899/white?text=Jeans', categoryId: 2, stock: 75, rating: 4.0 },
  { id: 9, name: 'Chaqueta de Cuero', description: 'Chaqueta de cuero sintético premium con forro interior térmico', price: 149.99, image: 'https://placehold.co/300x300/ec4899/white?text=Chaqueta', categoryId: 2, stock: 20, rating: 4.6 },
  { id: 10, name: 'Vestido Elegante', description: 'Vestido de noche con diseño contemporáneo y tela fluida', price: 89.99, image: 'https://placehold.co/300x300/ec4899/white?text=Vestido', categoryId: 2, stock: 35, rating: 4.3 },
  { id: 11, name: 'Zapatillas Running', description: 'Zapatillas deportivas con suela de gel amortiguante y malla transpirable', price: 119.99, image: 'https://placehold.co/300x300/ec4899/white?text=Zapatillas', categoryId: 2, stock: 60, rating: 4.5 },
  { id: 12, name: 'Sudadera Oversize', description: 'Sudadera de algodón premium con capucha en talla oversize', price: 49.99, image: 'https://placehold.co/300x300/ec4899/white?text=Sudadera', categoryId: 2, stock: 45, rating: 4.2 },

  // Hogar (categoryId: 3)
  { id: 13, name: 'Lámpara de Mesa LED', description: 'Lámpara moderna con luz regulable en 3 tonos y base de carga wireless', price: 79.99, image: 'https://placehold.co/300x300/22c55e/white?text=Lampara', categoryId: 3, stock: 55, rating: 4.4 },
  { id: 14, name: 'Set de Sábanas 400H', description: 'Juego de sábanas de algodón egipcio de 400 hilos, tamaño queen', price: 69.99, image: 'https://placehold.co/300x300/22c55e/white?text=Sabanas', categoryId: 3, stock: 40, rating: 4.3 },
  { id: 15, name: 'Cafetera Espresso', description: 'Máquina de café espresso automática con molinillo integrado', price: 249.99, image: 'https://placehold.co/300x300/22c55e/white?text=Cafetera', categoryId: 3, stock: 20, rating: 4.7 },
  { id: 16, name: 'Robot Aspirador', description: 'Aspiradora robot inteligente con mapeo láser y app de control remoto', price: 399.99, image: 'https://placehold.co/300x300/22c55e/white?text=Robot', categoryId: 3, stock: 15, rating: 4.5 },
  { id: 17, name: 'Set de Cuchillos Chef', description: 'Set de 6 cuchillos profesionales de acero inoxidable con bloque', price: 89.99, image: 'https://placehold.co/300x300/22c55e/white?text=Cuchillos', categoryId: 3, stock: 30, rating: 4.6 },
  { id: 18, name: 'Organizador de Escritorio', description: 'Organizador multifuncional de bambú para escritorio con 5 compartimentos', price: 34.99, image: 'https://placehold.co/300x300/22c55e/white?text=Organizador', categoryId: 3, stock: 70, rating: 4.1 },

  // Deportes (categoryId: 4)
  { id: 19, name: 'Mancuernas Ajustables', description: 'Set de mancuernas de 2-20kg con sistema de ajuste rápido patentado', price: 179.99, image: 'https://placehold.co/300x300/f59e0b/white?text=Mancuernas', categoryId: 4, stock: 25, rating: 4.4 },
  { id: 20, name: 'Esterilla de Yoga', description: 'Esterilla antideslizante de 6mm con líneas de alineación y funda', price: 39.99, image: 'https://placehold.co/300x300/f59e0b/white?text=Esterilla', categoryId: 4, stock: 80, rating: 4.3 },
  { id: 21, name: 'Bicicleta Estática', description: 'Bicicleta de spinning con monitor digital y resistencia magnética de 16 niveles', price: 499.99, image: 'https://placehold.co/300x300/f59e0b/white?text=Bicicleta', categoryId: 4, stock: 10, rating: 4.6 },
  { id: 22, name: 'Balón de Fútbol Pro', description: 'Balón de fútbol profesional tamaño 5 con certificación FIFA Quality Pro', price: 49.99, image: 'https://placehold.co/300x300/f59e0b/white?text=Balon', categoryId: 4, stock: 60, rating: 4.2 },
  { id: 23, name: 'Raqueta de Tenis', description: 'Raqueta de tenis profesional de grafito con cuerdas de poliéster', price: 159.99, image: 'https://placehold.co/300x300/f59e0b/white?text=Raqueta', categoryId: 4, stock: 20, rating: 4.5 },
  { id: 24, name: 'Guantes de Box', description: 'Guantes de boxeo de 14oz con relleno de gel y cierre de velcro', price: 69.99, image: 'https://placehold.co/300x300/f59e0b/white?text=Guantes', categoryId: 4, stock: 35, rating: 4.3 },

  // Libros (categoryId: 5)
  { id: 25, name: 'Clean Code', description: 'A Handbook of Agile Software Craftsmanship por Robert C. Martin', price: 39.99, image: 'https://placehold.co/300x300/8b5cf6/white?text=Clean+Code', categoryId: 5, stock: 50, rating: 4.8 },
  { id: 26, name: 'Design Patterns', description: 'Elements of Reusable Object-Oriented Software - Gang of Four', price: 44.99, image: 'https://placehold.co/300x300/8b5cf6/white?text=Design+Patterns', categoryId: 5, stock: 35, rating: 4.7 },
  { id: 27, name: 'The Pragmatic Programmer', description: 'From Journeyman to Master - Edición 20 aniversario revisada', price: 49.99, image: 'https://placehold.co/300x300/8b5cf6/white?text=Pragmatic', categoryId: 5, stock: 30, rating: 4.9 },
  { id: 28, name: 'Refactoring', description: 'Improving the Design of Existing Code por Martin Fowler - 2da edición', price: 42.99, image: 'https://placehold.co/300x300/8b5cf6/white?text=Refactoring', categoryId: 5, stock: 40, rating: 4.6 },
  { id: 29, name: 'JavaScript: The Good Parts', description: 'Unearthing the Excellence in JavaScript por Douglas Crockford', price: 24.99, image: 'https://placehold.co/300x300/8b5cf6/white?text=JS+Good+Parts', categoryId: 5, stock: 55, rating: 4.4 },
  { id: 30, name: 'Learning React', description: 'Modern Patterns for Developing React Apps - Edición actualizada', price: 34.99, image: 'https://placehold.co/300x300/8b5cf6/white?text=Learning+React', categoryId: 5, stock: 45, rating: 4.3 },
];

export const currentUser: User = {
  id: 1,
  name: 'Juan García',
  email: 'juan.garcia@email.com',
  phone: '+34 612 345 678',
  address: {
    street: 'Calle Principal 123',
    city: 'Madrid',
    zipCode: '28001',
    country: 'España',
  },
};

export const orders: Order[] = [
  {
    id: 1001,
    userId: 1,
    items: [
      { productId: 1, productName: 'Smartphone Pro Max', quantity: 1, unitPrice: 999.99 },
      { productId: 3, productName: 'Auriculares Bluetooth', quantity: 2, unitPrice: 199.99 },
    ],
    total: 1399.97,
    status: 'delivered',
    createdAt: '2025-12-15T10:30:00Z',
  },
  {
    id: 1002,
    userId: 1,
    items: [
      { productId: 15, productName: 'Cafetera Espresso', quantity: 1, unitPrice: 249.99 },
    ],
    total: 249.99,
    status: 'shipped',
    createdAt: '2026-01-20T14:15:00Z',
  },
  {
    id: 1003,
    userId: 1,
    items: [
      { productId: 25, productName: 'Clean Code', quantity: 1, unitPrice: 39.99 },
      { productId: 27, productName: 'The Pragmatic Programmer', quantity: 1, unitPrice: 49.99 },
      { productId: 28, productName: 'Refactoring', quantity: 1, unitPrice: 42.99 },
    ],
    total: 132.97,
    status: 'delivered',
    createdAt: '2025-11-05T09:00:00Z',
  },
  {
    id: 1004,
    userId: 1,
    items: [
      { productId: 19, productName: 'Mancuernas Ajustables', quantity: 1, unitPrice: 179.99 },
      { productId: 20, productName: 'Esterilla de Yoga', quantity: 2, unitPrice: 39.99 },
    ],
    total: 259.97,
    status: 'pending',
    createdAt: '2026-02-28T16:45:00Z',
  },
];
