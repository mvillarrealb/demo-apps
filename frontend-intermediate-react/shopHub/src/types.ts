// Should be in /models/Product.ts, /models/User.ts, /models/Order.ts, etc.

export interface Product {
  id: number;
  name: string;
  description: string;
  price: number;
  image: string;
  categoryId: number;
  stock: number;
  rating: number;
}

export interface Category {
  id: number;
  name: string;
  description: string;
  image: string;
}

export interface User {
  id: number;
  name: string;
  email: string;
  phone: string;
  address: {
    street: string;
    city: string;
    zipCode: string;
    country: string;
  };
}

export interface CartItem {
  quantity: number;
}

export interface Order {
  id: number;
  userId: number;
  items: OrderItem[];
  total: number;
  status: "pending" | "shipped" | "delivered";
  createdAt: string;
}

export interface OrderItem {
  productId: number;
  productName: string;
  quantity: number;
  unitPrice: number;
}

export interface CreateOrderDto {
  userId: number;
  items: { productId: number; quantity: number; unitPrice: number }[];
  total: number;
  shippingAddress: {
    name: string;
    street: string;
    city: string;
    zipCode: string;
    country: string;
  };
}
