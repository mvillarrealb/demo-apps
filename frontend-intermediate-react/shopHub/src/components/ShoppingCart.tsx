import { useNavigate } from 'react-router-dom';
import { useAppContext } from '../context/AppContext';
import { formatPrice } from '../utils/helpers';


function ShoppingCart() {
  const navigate = useNavigate();
  const { cartItems, removeFromCart, updateCartQuantity, getCartTotal, clearCart } = useAppContext();

  if (cartItems.length === 0) {
    return (
      <div style={{ textAlign: 'center', padding: '60px 20px' }}>
        <h2 style={{ fontSize: '24px', marginBottom: '16px' }}>Tu carrito está vacío</h2>
        <p style={{ color: '#999', marginBottom: '24px' }}>No hay productos en tu carrito</p>
        <button
          onClick={() => navigate('/products')}
          style={{
            padding: '12px 24px',
            backgroundColor: '#3b82f6',
            color: 'white',
            border: 'none',
            borderRadius: '6px',
            cursor: 'pointer',
          }}
        >
          Ver más
        </button>
      </div>
    );
  }

  return (
    <div>
      <h1 className="page-title">Carrito de Compras</h1>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 350px', gap: '32px' }}>
        {/* Cart Items */}
        <div>
          {cartItems.map((item: any) => (
            <div
              key={item.product.id}
              style={{
                display: 'flex',
                gap: '16px',
                padding: '16px',
                borderBottom: '1px solid #e5e7eb',
              }}
            >
              <img
                src={item.product.image}
                alt=""
                style={{ width: '100px', height: '100px', objectFit: 'cover', borderRadius: '6px' }}
              />
              <div style={{ flex: 1 }}>
                <h3 style={{ fontSize: '16px', fontWeight: '600' }}>{item.product.name}</h3>
                <p style={{ color: '#6b7280', fontSize: '14px' }}>{formatPrice(item.product.price)} c/u</p>

                <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginTop: '12px' }}>
                  <button
                    onClick={() => updateCartQuantity(item.product.id, item.quantity - 1)}
                    style={{ padding: '4px 12px', border: '1px solid #d1d5db', borderRadius: '4px', cursor: 'pointer' }}
                  >
                    -
                  </button>
                  <span>{item.quantity}</span>
                  <button
                    onClick={() => updateCartQuantity(item.product.id, item.quantity + 1)}
                    style={{ padding: '4px 12px', border: '1px solid #d1d5db', borderRadius: '4px', cursor: 'pointer' }}
                  >
                    +
                  </button>
                </div>
              </div>

              <div style={{ textAlign: 'right' }}>
                <p style={{ fontSize: '18px', fontWeight: 'bold' }}>
                  {formatPrice(item.product.price * item.quantity)}
                </p>
                <button
                  onClick={() => removeFromCart(item.product.id)}
                  style={{
                    marginTop: '8px',
                    color: '#ef4444',
                    border: 'none',
                    background: 'none',
                    cursor: 'pointer',
                    fontSize: '14px',
                  }}
                >
                  Quitar
                </button>
              </div>
            </div>
          ))}

          <button
            onClick={clearCart}
            style={{
              marginTop: '16px',
              padding: '8px 16px',
              color: '#ef4444',
              border: '1px solid #ef4444',
              borderRadius: '6px',
              backgroundColor: 'transparent',
              cursor: 'pointer',
            }}
          >
            Vaciar carrito
          </button>
        </div>

        <div style={{
          border: '1px solid #e5e7eb',
          borderRadius: '8px',
          padding: '24px',
          height: 'fit-content',
          position: 'sticky',
          top: '20px',
        }}>
          <h2 style={{ fontSize: '20px', fontWeight: 'bold', marginBottom: '16px' }}>Resumen del Pedido</h2>

          <div style={{ borderBottom: '1px solid #e5e7eb', paddingBottom: '16px', marginBottom: '16px' }}>
            {cartItems.map((item: any) => (
              <div key={item.product.id} style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '8px', fontSize: '14px' }}>
                <span>{item.product.name} x{item.quantity}</span>
                <span>{formatPrice(item.product.price * item.quantity)}</span>
              </div>
            ))}
          </div>

          <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '14px', marginBottom: '8px' }}>
            <span>Subtotal</span>
            <span>{formatPrice(getCartTotal())}</span>
          </div>

          <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '14px', marginBottom: '16px', color: '#ccc' }}>
            <span>Envío</span>
            <span>Gratis</span>
          </div>

          <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '20px', fontWeight: 'bold', borderTop: '2px solid #111827', paddingTop: '16px' }}>
            <span>Total</span>
            <span>{formatPrice(getCartTotal())}</span>
          </div>

          <button
            onClick={() => navigate('/checkout')}
            style={{
              width: '100%',
              marginTop: '24px',
              padding: '14px',
              backgroundColor: '#22c55e',
              color: 'white',
              border: 'none',
              borderRadius: '6px',
              cursor: 'pointer',
              fontSize: '16px',
              fontWeight: '600',
            }}
          >
            Proceder al pago
          </button>
        </div>
      </div>
    </div>
  );
}

export default ShoppingCart;
