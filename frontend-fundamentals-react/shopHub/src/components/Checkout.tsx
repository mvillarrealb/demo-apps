import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAppContext } from '../context/AppContext';
import { createOrder } from '../services/api';
import { formatPrice } from '../utils/helpers';


function Checkout() {
  const navigate = useNavigate();
  const { cartItems, getCartTotal, clearCart, user } = useAppContext();

  const [name, setName] = useState('');
  const [street, setStreet] = useState('');
  const [city, setCity] = useState('');
  const [zipCode, setZipCode] = useState('');
  const [country, setCountry] = useState('');
  const [errors, setErrors] = useState<any>({});
  const [submitting, setSubmitting] = useState(false);
  const [orderPlaced, setOrderPlaced] = useState(false);

  const validateForm = () => {
    const newErrors: any = {};

    if (!name.trim()) {
      newErrors.name = 'El nombre es requerido';
    }
    if (!street.trim()) {
      newErrors.street = 'La dirección es requerida';
    }
    if (!city.trim()) {
      newErrors.city = 'La ciudad es requerida';
    }
    if (!zipCode.trim()) {
      newErrors.zipCode = 'El código postal es requerido';
    } else if (zipCode.length < 3) {
      newErrors.zipCode = 'Código postal inválido';
    }
    if (!country.trim()) {
      newErrors.country = 'El país es requerido';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e: any) => {
    e.preventDefault();

    if (!validateForm()) return;

    setSubmitting(true);
    try {
      await createOrder({
        userId: user?.id || 1,
        items: cartItems.map((item: any) => ({
          productId: item.product.id,
          quantity: item.quantity,
          unitPrice: item.product.price,
        })),
        total: getCartTotal(),
        shippingAddress: {
          name,
          street,
          city,
          zipCode,
          country,
        },
      });
      clearCart();
      setOrderPlaced(true);
    } catch (err) {
      setErrors({ submit: 'Error al procesar el pedido. Intenta de nuevo.' });
    } finally {
      setSubmitting(false);
    }
  };

  if (orderPlaced) {
    return (
      <div style={{ textAlign: 'center', padding: '60px 20px' }}>
        <h2 style={{ fontSize: '28px', fontWeight: 'bold', marginBottom: '16px', color: '#22c55e' }}>
          ¡Pedido Confirmado!
        </h2>
        <p style={{ color: '#6b7280', marginBottom: '24px' }}>
          Tu pedido ha sido procesado exitosamente. Recibirás un email de confirmación.
        </p>
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
          Seguir comprando
        </button>
      </div>
    );
  }

  if (cartItems.length === 0) {
    return (
      <div style={{ textAlign: 'center', padding: '60px' }}>
        <p>No hay productos en el carrito</p>
        <button
          onClick={() => navigate('/products')}
          style={{ marginTop: '16px', padding: '8px 16px', cursor: 'pointer' }}
        >
          Ver productos
        </button>
      </div>
    );
  }

  return (
    <div>
      <h1 className="page-title">Checkout</h1>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 400px', gap: '32px' }}>
        {/* Shipping Form */}
        <form onSubmit={handleSubmit}>
          <h2 style={{ fontSize: '20px', fontWeight: 'bold', marginBottom: '16px' }}>Datos de Envío</h2>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
            <div>
              <input
                type="text"
                placeholder="Nombre completo"
                value={name}
                onChange={(e) => setName(e.target.value)}
                style={{
                  width: '100%',
                  padding: '10px 12px',
                  border: `1px solid ${errors.name ? 'red' : '#d1d5db'}`,
                  borderRadius: '6px',
                }}
              />
              {errors.name && <p style={{ color: 'red', fontSize: '12px', marginTop: '4px' }}>{errors.name}</p>}
            </div>

            <div>
              <input
                type="text"
                placeholder="Dirección"
                value={street}
                onChange={(e) => setStreet(e.target.value)}
                style={{
                  width: '100%',
                  padding: '10px 12px',
                  border: `1px solid ${errors.street ? 'red' : '#d1d5db'}`,
                  borderRadius: '6px',
                }}
              />
              {errors.street && <p style={{ color: 'red', fontSize: '12px', marginTop: '4px' }}>{errors.street}</p>}
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
              <div>
                <input
                  type="text"
                  placeholder="Ciudad"
                  value={city}
                  onChange={(e) => setCity(e.target.value)}
                  style={{
                    width: '100%',
                    padding: '10px 12px',
                    border: `1px solid ${errors.city ? 'red' : '#d1d5db'}`,
                    borderRadius: '6px',
                  }}
                />
                {errors.city && <p style={{ color: 'red', fontSize: '12px', marginTop: '4px' }}>{errors.city}</p>}
              </div>

              <div>
                <input
                  type="text"
                  placeholder="Código postal"
                  value={zipCode}
                  onChange={(e) => setZipCode(e.target.value)}
                  style={{
                    width: '100%',
                    padding: '10px 12px',
                    border: `1px solid ${errors.zipCode ? 'red' : '#d1d5db'}`,
                    borderRadius: '6px',
                  }}
                />
                {errors.zipCode && <p style={{ color: 'red', fontSize: '12px', marginTop: '4px' }}>{errors.zipCode}</p>}
              </div>
            </div>

            <div>
              <input
                type="text"
                placeholder="País"
                value={country}
                onChange={(e) => setCountry(e.target.value)}
                style={{
                  width: '100%',
                  padding: '10px 12px',
                  border: `1px solid ${errors.country ? 'red' : '#d1d5db'}`,
                  borderRadius: '6px',
                }}
              />
              {errors.country && <p style={{ color: 'red', fontSize: '12px', marginTop: '4px' }}>{errors.country}</p>}
            </div>

            {errors.submit && (
              <div className="error-message">{errors.submit}</div>
            )}

            <button
              type="submit"
              disabled={submitting}
              style={{
                padding: '14px',
                backgroundColor: submitting ? '#9ca3af' : '#22c55e',
                color: 'white',
                border: 'none',
                borderRadius: '6px',
                cursor: submitting ? 'not-allowed' : 'pointer',
                fontSize: '16px',
                fontWeight: '600',
              }}
            >
              {submitting ? 'Procesando...' : 'Confirmar Pedido'}
            </button>
          </div>
        </form>

        <div style={{
          border: '1px solid #e5e7eb',
          borderRadius: '8px',
          padding: '24px',
          height: 'fit-content',
        }}>
          <h2 style={{ fontSize: '20px', fontWeight: 'bold', marginBottom: '16px' }}>Resumen del Pedido</h2>

          {cartItems.map((item: any) => (
            <div key={item.product.id} style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '8px', fontSize: '14px' }}>
              <span>{item.product.name} x{item.quantity}</span>
              <span>{formatPrice(item.product.price * item.quantity)}</span>
            </div>
          ))}

          <div style={{ borderTop: '2px solid #111827', marginTop: '16px', paddingTop: '16px', display: 'flex', justifyContent: 'space-between', fontSize: '20px', fontWeight: 'bold' }}>
            <span>Total</span>
            <span>{formatPrice(getCartTotal())}</span>
          </div>
        </div>
      </div>
    </div>
  );
}

export default Checkout;
