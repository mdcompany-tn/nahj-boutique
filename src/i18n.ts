export type Lang = "fr" | "ar";
const dict = {
  home: ["Accueil", "الرئيسية"], shop: ["Boutique", "المتجر"], collections: ["Collections", "المجموعات"], new: ["Nouveautés", "الجديد"],
  best: ["Meilleures ventes", "الأكثر مبيعًا"], offers: ["Offres", "العروض"], about: ["À propos", "من نحن"], contact: ["Contact", "اتصل بنا"],
  search: ["Rechercher", "بحث"], account: ["Compte", "حسابي"], wishlist: ["Favoris", "المفضلة"], bag: ["Panier", "السلة"],
  addToBag: ["Ajouter au panier", "أضف إلى السلة"], soldOut: ["Épuisé", "نفدت الكمية"], size: ["Taille", "المقاس"], color: ["Couleur", "اللون"],
  checkout: ["Commander", "إتمام الطلب"], emptyBag: ["Votre panier est vide.", "سلتك فارغة."], subtotal: ["Sous-total", "المجموع الفرعي"],
  delivery: ["Livraison", "التوصيل"], total: ["Total", "المجموع"], discount: ["Remise", "التخفيض"], viewAll: ["Tout voir", "عرض الكل"],
  continue: ["Continuer mes achats", "مواصلة التسوق"], newsletter: ["La lettre de la rue", "نشرة النهج"], subscribe: ["S’inscrire", "اشترك"],
  cod: ["Paiement à la livraison", "الدفع عند الاستلام"], lowStock: ["Plus que", "بقي"], pieces: ["pièces", "قطع"], track: ["Suivre ma commande", "تتبع طلبي"],
} satisfies Record<string, [string, string]>;
export type Key = keyof typeof dict;
export const t = (lang: Lang, k: Key) => dict[k][lang === "ar" ? 1 : 0];
