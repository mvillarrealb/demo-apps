
export function formatPrice(price: any) {
  return '$' + Number(price).toFixed(2);
}

export function formatDate(dateString: any) {
  const date = new Date(dateString);
  return date.toLocaleDateString();
}

export function truncateText(text: string, maxLength: number) {
  if (text.length <= maxLength) return text;
  return text.substring(0, maxLength) + '...';
}

export function getStarRating(rating: number) {
  const stars = [];
  for (let i = 1; i <= 5; i++) {
    if (i <= Math.floor(rating)) {
      stars.push('★');
    } else if (i - rating < 1) {
      stars.push('⯨');
    } else {
      stars.push('☆');
    }
  }
  return stars.join('');
}

export function calculateDiscount(price: number, discount: number) {
  return price - (price * discount) / 100;
}

export function generateId() {
  return Math.random().toString(36).substr(2, 9);
}

export function debounce(fn: Function, ms: number) {
  let timer: any;
  return (...args: any[]) => {
    clearTimeout(timer);
    timer = setTimeout(() => fn(...args), ms);
  };
}

export function slugify(text: string) {
  return text
    .toLowerCase()
    .replace(/[^\w ]+/g, '')
    .replace(/ +/g, '-');
}
