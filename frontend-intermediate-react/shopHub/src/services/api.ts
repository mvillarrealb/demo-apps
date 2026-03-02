import { products, categories, currentUser, orders } from '../data/mockData';
import { Product, Category, User, Order, CreateOrderDto } from '../types';

// Should be: productService.ts, userService.ts, orderService.ts, categoryService.ts

const delay = (ms: number) => new Promise(resolve => setTimeout(resolve, ms));

let mockUser = { ...currentUser };
let mockOrders = [...orders];
let nextOrderId = 1005;

export async function getProducts(): Promise<Product[]> {
  await delay(500);
  return [...products];
}

export async function getProductById(id: number): Promise<Product> {
  await delay(300);
  const product = products.find(p => p.id === id);
  if (!product) throw new Error('Producto no encontrado');
  return { ...product };
}

export async function getCategories(): Promise<Category[]> {
  await delay(300);
  return [...categories];
}

export async function getUser(): Promise<User> {
  await delay(400);
  return { ...mockUser };
}

export async function updateUser(data: any): Promise<User> {
  await delay(600);
  mockUser = { ...mockUser, ...data };
  return { ...mockUser };
}

export async function createOrder(orderData: CreateOrderDto): Promise<Order> {
  await delay(800);
  const newOrder: Order = {
    id: nextOrderId++,
    userId: orderData.userId,
    items: orderData.items.map((item: any) => ({
      ...item,
      productName: products.find(p => p.id === item.productId)?.name || 'Unknown',
    })),
    total: orderData.total,
    status: 'pending',
    createdAt: new Date().toISOString(),
  };
  mockOrders.push(newOrder);
  return newOrder;
}

export async function getOrders(): Promise<Order[]> {
  await delay(500);
  return [...mockOrders];
}
