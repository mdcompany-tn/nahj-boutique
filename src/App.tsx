import { lazy, Suspense, useEffect } from "react";
import { Route, Routes, useLocation } from "react-router-dom";
import Layout from "./components/Layout";
import Home from "./pages/Home";
import Shop from "./pages/Shop";
import Collections from "./pages/Collections";
import ProductPage from "./pages/Product";
import Wishlist from "./pages/Wishlist";
import NotFound from "./pages/NotFound";
import Checkout from "./pages/Checkout";
import OrderPage from "./pages/Order";
import { About, Contact } from "./pages/Info";
import Account from "./pages/Account";

const Admin = lazy(() => import("./admin/Admin"));

export default function App() {
  const { pathname } = useLocation();
  useEffect(() => { window.scrollTo({ top: 0 }); }, [pathname]);

  return (
    <Routes>
      <Route path="/admin/*" element={<Suspense fallback={<div className="admin-loading">Chargement…</div>}><Admin /></Suspense>} />
      <Route element={<Layout />}>
        <Route index element={<Home />} />
        <Route path="shop" element={<Shop mode="all" />} />
        <Route path="new" element={<Shop mode="new" />} />
        <Route path="best-sellers" element={<Shop mode="best" />} />
        <Route path="offers" element={<Shop mode="offers" />} />
        <Route path="collections" element={<Collections />} />
        <Route path="collections/:slug" element={<Shop mode="collection" />} />
        <Route path="product/:slug" element={<ProductPage />} />
        <Route path="wishlist" element={<Wishlist />} />
        <Route path="checkout" element={<Checkout />} />
        <Route path="order/:number" element={<OrderPage />} />
        <Route path="track" element={<OrderPage />} />
        <Route path="about" element={<About />} />
        <Route path="contact" element={<Contact />} />
        <Route path="account" element={<Account />} />
        <Route path="*" element={<NotFound />} />
      </Route>
    </Routes>
  );
}
