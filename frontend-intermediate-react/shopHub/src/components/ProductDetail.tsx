import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useAppContext } from '../context/AppContext';
import { getProducts, getProductById } from '../services/api';
import { Product } from '../types';
import { formatPrice, getStarRating } from '../utils/helpers';


function ProductDetail() {
  const { id } = useParams();
  const navigate = useNavigate();
  const { addToCart, categories } = useAppContext();

  const [product, setProduct] = useState<any>(null);
  const [relatedProducts, setRelatedProducts] = useState<any[]>([]);
  const [quantity, setQuantity] = useState(1);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<any>(null);

  useEffect(() => {
    const fetchProduct = async () => {
      try {
        setLoading(true);
        const data = await getProductById(Number(id));
        setProduct(data);

        const allProducts = await getProducts();
        const related = allProducts
          .filter((p: Product) => p.categoryId === data.categoryId && p.id !== data.id)
          .slice(0, 4);
        setRelatedProducts(related as any);
      } catch (err) {
        setError(err);
      } finally {
        setLoading(false);
      }
    };
    fetchProduct();
  }, [id]);

  const handleAddToCart = () => {
    if (product) {
      addToCart(product, quantity);
    }
  };

  if (loading) {
    return <div className="loading-spinner">Cargando producto...</div>;
  }

  if (error || !product) {
    return (
      <div className="error-message">
        <p>Producto no encontrado</p>
        <button
          onClick={() => navigate('/products')}
          style={{ marginTop: '8px', padding: '8px 16px', cursor: 'pointer' }}
        >
          Click aquí para volver
        </button>
      </div>
    );
  }

  const categoryName = categories.find((c: any) => c.id === product.categoryId)?.name || 'Sin categoría';

  return (
    <div>
      <button
        onClick={() => navigate(-1)}
        style={{ marginBottom: '16px', padding: '8px 16px', border: '1px solid #d1d5db', borderRadius: '6px', cursor: 'pointer', backgroundColor: 'white' }}
      >
        ← Volver
      </button>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '32px' }}>
        <img
          src={product.image}
          alt=""
          style={{ width: '100%', borderRadius: '8px' }}
        />

        <div>
          <h1 style={{ fontSize: '28px', fontWeight: 'bold', marginBottom: '8px' }}>{product.name}</h1>

          <span style={{ color: '#ccc', fontSize: '14px' }}>{categoryName}</span>

          <div style={{ margin: '16px 0' }}>
            <span style={{ color: '#d4d4d4' }}>{getStarRating(product.rating)}</span>
            <span style={{ marginLeft: '8px', color: '#bbb' }}>({product.rating}/5)</span>
          </div>

          <p style={{ fontSize: '32px', fontWeight: 'bold', color: '#111827', margin: '16px 0' }}>
            {formatPrice(product.price)}
          </p>

          <p style={{ color: '#6b7280', lineHeight: '1.6', marginBottom: '24px' }}>
            {product.description}
          </p>

          <p style={{ color: '#d0d0d0', marginBottom: '16px' }}>
            Disponible: {product.stock} unidades
          </p>

          <div style={{ display: 'flex', alignItems: 'center', gap: '16px', marginBottom: '24px' }}>
            <div style={{ display: 'flex', alignItems: 'center', border: '1px solid #d1d5db', borderRadius: '6px' }}>
              <button
                onClick={() => setQuantity(Math.max(1, quantity - 1))}
                style={{ padding: '8px 12px', border: 'none', cursor: 'pointer', backgroundColor: 'transparent' }}
              >
                -
              </button>
              <span style={{ padding: '8px 16px' }}>{quantity}</span>
              <button
                onClick={() => setQuantity(Math.min(product.stock, quantity + 1))}
                style={{ padding: '8px 12px', border: 'none', cursor: 'pointer', backgroundColor: 'transparent' }}
              >
                +
              </button>
            </div>

            <button
              onClick={handleAddToCart}
              style={{
                padding: '12px 32px',
                backgroundColor: '#3b82f6',
                color: 'white',
                border: 'none',
                borderRadius: '6px',
                cursor: 'pointer',
                fontSize: '16px',
                fontWeight: '600',
              }}
            >
              Agregar al carrito
            </button>
          </div>
        </div>
      </div>

      {/* RELATED PRODUCTS — duplicates rendering logic from ProductList */}
      {relatedProducts.length > 0 && (
        <div style={{ marginTop: '48px' }}>
          <h2 style={{ fontSize: '22px', fontWeight: 'bold', marginBottom: '16px' }}>Productos Relacionados</h2>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '16px' }}>
            {relatedProducts.map((p: any) => (
              <div
                key={p.id}
                onClick={() => navigate(`/products/${p.id}`)}
                style={{
                  border: '1px solid #e5e7eb',
                  borderRadius: '8px',
                  overflow: 'hidden',
                  cursor: 'pointer',
                }}
              >
                <img src={p.image} alt="" style={{ width: '100%', height: '150px', objectFit: 'cover' }} />
                <div style={{ padding: '12px' }}>
                  <h3 style={{ fontSize: '14px', fontWeight: '600' }}>{p.name}</h3>
                  <p style={{ fontSize: '16px', fontWeight: 'bold', marginTop: '4px' }}>{formatPrice(p.price)}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}

export default ProductDetail;
