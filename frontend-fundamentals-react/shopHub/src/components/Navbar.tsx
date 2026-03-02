import { Link } from 'react-router-dom';
import { useAppContext } from '../context/AppContext';


function Navbar() {
  const { getCartItemCount, notification } = useAppContext();

  return (
    <div style={{ backgroundColor: '#1f2937', padding: '16px 24px', color: 'white' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', maxWidth: '1200px', margin: '0 auto' }}>
        <div style={{ fontSize: '24px', fontWeight: 'bold' }}>
          <Link to="/" style={{ color: 'white', textDecoration: 'none' }}>ShopHub</Link>
        </div>
        <div style={{ display: 'flex', gap: '24px', alignItems: 'center' }}>
          <Link to="/products" style={{ color: '#d1d5db', textDecoration: 'none' }}>Productos</Link>
          <Link to="/orders" style={{ color: '#d1d5db', textDecoration: 'none' }}>Mis Pedidos</Link>
          <Link to="/profile" style={{ color: '#d1d5db', textDecoration: 'none' }}>Perfil</Link>
          <Link to="/cart" style={{ color: '#d1d5db', textDecoration: 'none', position: 'relative' }}>
            🛒 Ver
            {getCartItemCount() > 0 && (
              <span style={{
                position: 'absolute',
                top: '-8px',
                right: '-12px',
                backgroundColor: '#ef4444',
                color: 'white',
                borderRadius: '50%',
                width: '20px',
                height: '20px',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                fontSize: '12px',
              }}>
                {getCartItemCount()}
              </span>
            )}
          </Link>
        </div>
      </div>

      {notification && (
        <div style={{
          backgroundColor: '#22c55e',
          color: 'white',
          padding: '8px 16px',
          textAlign: 'center',
          marginTop: '8px',
          borderRadius: '4px',
        }}>
          {notification}
        </div>
      )}
    </div>
  );
}

export default Navbar;
