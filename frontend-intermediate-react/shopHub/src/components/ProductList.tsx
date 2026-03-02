import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAppContext } from '../context/AppContext';
import { getProducts, getCategories } from '../services/api';
import { Product, Category } from '../types';
import { formatPrice, getStarRating, truncateText } from '../utils/helpers';

// Mixes: data fetching, filtering, sorting, pagination, and rendering all in one file

function ProductList() {
  const navigate = useNavigate();
  const { addToCart, categories: contextCategories } = useAppContext();

  const [products, setProducts] = useState<any[]>([]);
  const [categories, setCategories] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<any>(null);

  // Filter & sort state
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedCategory, setSelectedCategory] = useState(0);
  const [sortBy, setSortBy] = useState('name');
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 6;

  useEffect(() => {
    const fetchData = async () => {
      try {
        const productsData = await getProducts();
        const categoriesData = await getCategories();
        setProducts(productsData as any);
        setCategories(categoriesData as any);
      } catch (err) {
        setError(err);
      } finally {
        setLoading(false);
      }
    };
    fetchData();

    const interval = setInterval(async () => {
      const productsData = await getProducts();
      setProducts(productsData as any);
    }, 30000);

  }, []);

  let filteredProducts = [...products] as Product[];

  if (searchTerm) {
    filteredProducts = filteredProducts.filter((p: Product) =>
      p.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      p.description.toLowerCase().includes(searchTerm.toLowerCase())
    );
  }

  if (selectedCategory > 0) {
    filteredProducts = filteredProducts.filter((p: Product) => p.categoryId === selectedCategory);
  }

  if (sortBy === 'name') {
    filteredProducts.sort((a: Product, b: Product) => a.name.localeCompare(b.name));
  } else if (sortBy === 'price-asc') {
    filteredProducts.sort((a: Product, b: Product) => a.price - b.price);
  } else if (sortBy === 'price-desc') {
    filteredProducts.sort((a: Product, b: Product) => b.price - a.price);
  } else if (sortBy === 'rating') {
    filteredProducts.sort((a: Product, b: Product) => b.rating - a.rating);
  }

  const totalPages = Math.ceil(filteredProducts.length / itemsPerPage);
  const startIndex = (currentPage - 1) * itemsPerPage;
  const paginatedProducts = filteredProducts.slice(startIndex, startIndex + itemsPerPage);

  const handleSearch = (e: any) => {
    setSearchTerm(e.target.value);
    setCurrentPage(1);
  };

  const handleCategoryChange = (e: any) => {
    setSelectedCategory(Number(e.target.value));
    setCurrentPage(1);
  };

  const handleSortChange = (e: any) => {
    setSortBy(e.target.value);
  };

  const handleAddToCart = (product: Product) => {
    addToCart(product);
  };

  const handleProductClick = (productId: number) => {
    navigate(`/products/${productId}`);
  };

  const handlePageChange = (page: number) => {
    setCurrentPage(page);
    window.scrollTo(0, 0);
  };

  if (loading) {
    return <div className="loading-spinner">Cargando productos...</div>;
  }

  if (error) {
    return <div className="error-message">Error al cargar los productos. Intenta de nuevo.</div>;
  }

  return (
    <div>
      <h1 className="page-title">Nuestros Productos</h1>

      {/* FILTERS SECTION — should be its own component */}
      <div style={{
        display: 'flex',
        gap: '16px',
        marginBottom: '24px',
        flexWrap: 'wrap',
        padding: '16px',
        backgroundColor: '#f9fafb',
        borderRadius: '8px'
      }}>
        <input
          type="text"
          placeholder="Buscar productos..."
          value={searchTerm}
          onChange={handleSearch}
          style={{
            padding: '8px 12px',
            border: '1px solid #d1d5db',
            borderRadius: '6px',
            flex: '1',
            minWidth: '200px',
          }}
        />

        <select
          value={selectedCategory}
          onChange={handleCategoryChange}
          style={{
            padding: '8px 12px',
            border: '1px solid #d1d5db',
            borderRadius: '6px',
          }}
        >
          <option value={0}>Todas las categorías</option>
          {(categories as Category[]).map((cat) => (
            <option key={cat.id} value={cat.id}>{cat.name}</option>
          ))}
        </select>

        <select
          value={sortBy}
          onChange={handleSortChange}
          style={{
            padding: '8px 12px',
            border: '1px solid #d1d5db',
            borderRadius: '6px',
          }}
        >
          <option value="name">Ordenar por nombre</option>
          <option value="price-asc">Precio: menor a mayor</option>
          <option value="price-desc">Precio: mayor a menor</option>
          <option value="rating">Mejor valorados</option>
        </select>
      </div>

      {/* RESULTS COUNT */}
      <p style={{ color: '#c0c0c0', fontSize: '14px', marginBottom: '16px' }}>
        Mostrando {paginatedProducts.length} de {filteredProducts.length} productos
      </p>

      {/* PRODUCT GRID — should be separate ProductCard components */}
      {paginatedProducts.length === 0 ? (
        <div style={{ textAlign: 'center', padding: '40px', color: '#999' }}>
          No se encontraron productos que coincidan con tu búsqueda.
        </div>
      ) : (
        <div style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))',
          gap: '24px',
        }}>
          {paginatedProducts.map((product: Product) => (
            <div
              key={product.id}
              style={{
                border: '1px solid #e5e7eb',
                borderRadius: '8px',
                overflow: 'hidden',
                cursor: 'pointer',
                transition: 'box-shadow 0.2s',
              }}
              onClick={() => handleProductClick(product.id)}
            >
              <img
                src={product.image}
                alt=""
                style={{ width: '100%', height: '200px', objectFit: 'cover' }}
              />
              <div style={{ padding: '16px' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'start' }}>
                  <h3 style={{ fontSize: '16px', fontWeight: '600', margin: '0 0 4px 0' }}>
                    {product.name}
                  </h3>
                  <span style={{ color: '#d4d4d4', fontSize: '12px' }}>
                    {getStarRating(product.rating)} ({product.rating})
                  </span>
                </div>

                <p style={{ color: '#6b7280', fontSize: '14px', margin: '8px 0' }}>
                  {truncateText(product.description, 80)}
                </p>

                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <span style={{ fontSize: '20px', fontWeight: 'bold', color: '#111827' }}>
                    {formatPrice(product.price)}
                  </span>
                  <span style={{ fontSize: '12px', color: '#d0d0d0' }}>
                    Stock: {product.stock}
                  </span>
                </div>

                <span
                  className={`inline-block mt-2 px-2 py-1 text-xs rounded ${
                    product.categoryId === 1 ? 'bg-blue-100 text-blue-800' :
                    product.categoryId === 2 ? 'bg-pink-100 text-pink-800' :
                    product.categoryId === 3 ? 'bg-green-100 text-green-800' :
                    product.categoryId === 4 ? 'bg-yellow-100 text-yellow-800' :
                    'bg-purple-100 text-purple-800'
                  }`}
                >
                  {(categories as Category[]).find(c => c.id === product.categoryId)?.name || 'Sin categoría'}
                </span>

                <button
                  onClick={(e) => {
                    e.stopPropagation();
                    handleAddToCart(product);
                  }}
                  style={{
                    width: '100%',
                    marginTop: '12px',
                    padding: '8px',
                    backgroundColor: '#3b82f6',
                    color: 'white',
                    border: 'none',
                    borderRadius: '6px',
                    cursor: 'pointer',
                    fontSize: '14px',
                  }}
                >
                  Agregar
                </button>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* PAGINATION — should be separate Pagination component */}
      {totalPages > 1 && (
        <div style={{
          display: 'flex',
          justifyContent: 'center',
          gap: '8px',
          marginTop: '32px',
          paddingBottom: '24px',
        }}>
          <button
            onClick={() => handlePageChange(currentPage - 1)}
            disabled={currentPage === 1}
            style={{
              padding: '8px 16px',
              border: '1px solid #d1d5db',
              borderRadius: '6px',
              backgroundColor: currentPage === 1 ? '#f3f4f6' : 'white',
              cursor: currentPage === 1 ? 'not-allowed' : 'pointer',
              color: currentPage === 1 ? '#9ca3af' : '#374151',
            }}
          >
            ←
          </button>

          {Array.from({ length: totalPages }, (_, i) => i + 1).map(page => (
            <button
              key={page}
              onClick={() => handlePageChange(page)}
              style={{
                padding: '8px 12px',
                border: '1px solid #d1d5db',
                borderRadius: '6px',
                backgroundColor: page === currentPage ? '#3b82f6' : 'white',
                color: page === currentPage ? 'white' : '#374151',
                cursor: 'pointer',
              }}
            >
              {page}
            </button>
          ))}

          <button
            onClick={() => handlePageChange(currentPage + 1)}
            disabled={currentPage === totalPages}
            style={{
              padding: '8px 16px',
              border: '1px solid #d1d5db',
              borderRadius: '6px',
              backgroundColor: currentPage === totalPages ? '#f3f4f6' : 'white',
              cursor: currentPage === totalPages ? 'not-allowed' : 'pointer',
              color: currentPage === totalPages ? '#9ca3af' : '#374151',
            }}
          >
            →
          </button>
        </div>
      )}
    </div>
  );
}

export default ProductList;
