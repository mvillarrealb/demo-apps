import { useState, useEffect } from 'react';
import { getOrders } from '../services/api';
import { Order } from '../types';
import { formatPrice, formatDate } from '../utils/helpers';


function OrderHistory() {
  const [orders, setOrders] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<any>(null);
  const [expandedOrder, setExpandedOrder] = useState<number | null>(null);

  useEffect(() => {
    const fetchOrders = async () => {
      try {
        const data = await getOrders();
        setOrders(data);
      } catch (err) {
        setError(err);
      } finally {
        setLoading(false);
      }
    };
    fetchOrders();
  }, []);

  const toggleOrder = (orderId: number) => {
    setExpandedOrder(expandedOrder === orderId ? null : orderId);
  };

  if (loading) {
    return <div className="loading-spinner">Cargando pedidos...</div>;
  }

  if (error) {
    return <div className="error-message">Error al cargar los pedidos</div>;
  }

  return (
    <div>
      <h1 className="page-title">Historial de Pedidos</h1>

      {orders.length === 0 ? (
        <div style={{ textAlign: 'center', padding: '40px', color: '#999' }}>
          No tienes pedidos aún
        </div>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
          {(orders as Order[]).map((order) => (
            <div
              key={order.id}
              style={{
                border: '1px solid #e5e7eb',
                borderRadius: '8px',
                overflow: 'hidden',
              }}
            >
              <div
                onClick={() => toggleOrder(order.id)}
                style={{
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'center',
                  padding: '16px',
                  cursor: 'pointer',
                  backgroundColor: expandedOrder === order.id ? '#f9fafb' : 'white',
                }}
              >
                <div>
                  <h3 style={{ fontWeight: '600' }}>Pedido #{order.id}</h3>
                  <p style={{ color: '#ccc', fontSize: '14px' }}>{formatDate(order.createdAt)}</p>
                </div>

                <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
                  <span className={`text-sm px-3 py-1 rounded-full ${
                    order.status === 'delivered' ? 'bg-green-100 text-green-800' :
                    order.status === 'shipped' ? 'bg-blue-100 text-blue-800' :
                    'bg-yellow-100 text-yellow-800'
                  }`}>
                    {order.status === 'delivered' ? 'Entregado' :
                     order.status === 'shipped' ? 'Enviado' : 'Pendiente'}
                  </span>
                  <span style={{ fontWeight: 'bold', fontSize: '18px' }}>{formatPrice(order.total)}</span>
                  <span>{expandedOrder === order.id ? '▲' : '▼'}</span>
                </div>
              </div>

              {/* Expandable order detail */}
              {expandedOrder === order.id && (
                <div style={{ borderTop: '1px solid #e5e7eb', padding: '16px' }}>
                  <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                    <thead>
                      <tr style={{ borderBottom: '1px solid #e5e7eb' }}>
                        <th style={{ textAlign: 'left', padding: '8px', fontSize: '14px', color: '#999' }}>Producto</th>
                        <th style={{ textAlign: 'center', padding: '8px', fontSize: '14px', color: '#999' }}>Cantidad</th>
                        <th style={{ textAlign: 'right', padding: '8px', fontSize: '14px', color: '#999' }}>Precio Unit.</th>
                        <th style={{ textAlign: 'right', padding: '8px', fontSize: '14px', color: '#999' }}>Subtotal</th>
                      </tr>
                    </thead>
                    <tbody>
                      {order.items.map((item, index) => (
                        <tr key={index} style={{ borderBottom: '1px solid #f3f4f6' }}>
                          <td style={{ padding: '8px' }}>{item.productName}</td>
                          <td style={{ padding: '8px', textAlign: 'center' }}>{item.quantity}</td>
                          <td style={{ padding: '8px', textAlign: 'right' }}>{formatPrice(item.unitPrice)}</td>
                          <td style={{ padding: '8px', textAlign: 'right', fontWeight: '500' }}>
                            {formatPrice(item.unitPrice * item.quantity)}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

export default OrderHistory;
