import { useState, useEffect } from 'react';
import { useAppContext } from '../context/AppContext';
import { updateUser, getOrders } from '../services/api';
import { formatPrice, formatDate } from '../utils/helpers';


function UserProfile() {
  const { user, setUser } = useAppContext();

  const [isEditing, setIsEditing] = useState(false);
  const [editName, setEditName] = useState('');
  const [editEmail, setEditEmail] = useState('');
  const [editPhone, setEditPhone] = useState('');
  const [saving, setSaving] = useState(false);

  const [recentOrders, setRecentOrders] = useState<any[]>([]);
  const [ordersLoading, setOrdersLoading] = useState(true);

  useEffect(() => {
    const fetchOrders = async () => {
      try {
        const data = await getOrders();
        setRecentOrders(data.slice(0, 3));
      } catch (err) {
        console.error(err);
      } finally {
        setOrdersLoading(false);
      }
    };
    fetchOrders();
  }, []);

  const startEditing = () => {
    if (user) {
      setEditName(user.name);
      setEditEmail(user.email);
      setEditPhone(user.phone);
      setIsEditing(true);
    }
  };

  const handleSave = async () => {
    setSaving(true);
    try {
      const updated = await updateUser({
        name: editName,
        email: editEmail,
        phone: editPhone,
      });
      setUser(updated);
      setIsEditing(false);
    } catch (err) {
      console.error(err);
    } finally {
      setSaving(false);
    }
  };

  if (!user) {
    return <div className="loading-spinner">Cargando perfil...</div>;
  }

  return (
    <div>
      <h1 className="page-title">Mi Perfil</h1>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '32px' }}>
        {/* User Info Card */}
        <div style={{ border: '1px solid #e5e7eb', borderRadius: '8px', padding: '24px' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px' }}>
            <h2 style={{ fontSize: '20px', fontWeight: 'bold' }}>Información Personal</h2>
            {!isEditing && (
              <button
                onClick={startEditing}
                style={{
                  padding: '8px 16px',
                  backgroundColor: '#3b82f6',
                  color: 'white',
                  border: 'none',
                  borderRadius: '6px',
                  cursor: 'pointer',
                }}
              >
                Editar
              </button>
            )}
          </div>

          {isEditing ? (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
              <div>
                <input
                  type="text"
                  placeholder="Nombre"
                  value={editName}
                  onChange={(e) => setEditName(e.target.value)}
                  style={{ width: '100%', padding: '10px 12px', border: '1px solid #d1d5db', borderRadius: '6px' }}
                />
              </div>
              <div>
                <input
                  type="email"
                  placeholder="Email"
                  value={editEmail}
                  onChange={(e) => setEditEmail(e.target.value)}
                  style={{ width: '100%', padding: '10px 12px', border: '1px solid #d1d5db', borderRadius: '6px' }}
                />
              </div>
              <div>
                <input
                  type="tel"
                  placeholder="Teléfono"
                  value={editPhone}
                  onChange={(e) => setEditPhone(e.target.value)}
                  style={{ width: '100%', padding: '10px 12px', border: '1px solid #d1d5db', borderRadius: '6px' }}
                />
              </div>

              <div style={{ display: 'flex', gap: '12px' }}>
                <button
                  onClick={handleSave}
                  disabled={saving}
                  style={{
                    padding: '10px 24px',
                    backgroundColor: saving ? '#9ca3af' : '#22c55e',
                    color: 'white',
                    border: 'none',
                    borderRadius: '6px',
                    cursor: saving ? 'not-allowed' : 'pointer',
                  }}
                >
                  {saving ? 'Guardando...' : 'Guardar'}
                </button>
                <button
                  onClick={() => setIsEditing(false)}
                  style={{
                    padding: '10px 24px',
                    backgroundColor: 'transparent',
                    border: '1px solid #d1d5db',
                    borderRadius: '6px',
                    cursor: 'pointer',
                  }}
                >
                  Cancelar
                </button>
              </div>
            </div>
          ) : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
              <div>
                <span style={{ color: '#ccc', fontSize: '14px' }}>Nombre</span>
                <p style={{ fontWeight: '500' }}>{user.name}</p>
              </div>
              <div>
                <span style={{ color: '#ccc', fontSize: '14px' }}>Email</span>
                <p style={{ fontWeight: '500' }}>{user.email}</p>
              </div>
              <div>
                <span style={{ color: '#ccc', fontSize: '14px' }}>Teléfono</span>
                <p style={{ fontWeight: '500' }}>{user.phone}</p>
              </div>
              <div>
                <span style={{ color: '#ccc', fontSize: '14px' }}>Dirección</span>
                <p style={{ fontWeight: '500' }}>
                  {user.address.street}, {user.address.city}, {user.address.zipCode}, {user.address.country}
                </p>
              </div>
            </div>
          )}
        </div>

        <div style={{ border: '1px solid #e5e7eb', borderRadius: '8px', padding: '24px' }}>
          <h2 style={{ fontSize: '20px', fontWeight: 'bold', marginBottom: '16px' }}>Pedidos Recientes</h2>

          {ordersLoading ? (
            <p>Cargando pedidos...</p>
          ) : recentOrders.length === 0 ? (
            <p style={{ color: '#999' }}>No tienes pedidos aún</p>
          ) : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
              {recentOrders.map((order: any) => (
                <div key={order.id} style={{ border: '1px solid #e5e7eb', borderRadius: '6px', padding: '12px' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                    <span style={{ fontWeight: '600' }}>Pedido #{order.id}</span>
                    <span className={`text-sm px-2 py-1 rounded ${
                      order.status === 'delivered' ? 'bg-green-100 text-green-800' :
                      order.status === 'shipped' ? 'bg-blue-100 text-blue-800' :
                      'bg-yellow-100 text-yellow-800'
                    }`}>
                      {order.status === 'delivered' ? 'Entregado' :
                       order.status === 'shipped' ? 'Enviado' : 'Pendiente'}
                    </span>
                  </div>
                  <p style={{ color: '#ccc', fontSize: '12px', marginTop: '4px' }}>{formatDate(order.createdAt)}</p>
                  <p style={{ fontWeight: '500', marginTop: '4px' }}>{formatPrice(order.total)}</p>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

export default UserProfile;
