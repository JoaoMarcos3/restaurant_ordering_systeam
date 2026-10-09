import express from "express";
import { randomUUID } from "node:crypto";
import supabase from "./config/supabase.js";

const app = express();
app.use(express.json());

app.get("/", (_req, res) => {
  res.status(200).json({ message: "API Restaurante", version: "1.0.0" });
});

app.get("/categorias", async (_req, res) => {
  const { data, error } = await supabase.from("categories").select("*").order("name");
  if (error) return res.status(500).json({ message: "Erro ao buscar categorias.", detail: error.message });
  return res.status(200).json(data);
});

app.get("/categorias/:id", async (req, res) => {
  const { data, error } = await supabase.from("categories").select("*").eq("id", req.params.id).maybeSingle();
  if (error) return res.status(500).json({ message: "Erro ao buscar categoria.", detail: error.message });
  if (!data) return res.status(404).json({ message: "Categoria não encontrada." });
  return res.status(200).json(data);
});

app.post("/categorias", async (req, res) => {
  const { name, description } = req.body;
  if (typeof name !== "string" || !name.trim()) return res.status(400).json({ message: "Informe o nome da categoria." });
  const { data, error } = await supabase.from("categories").insert({ id: randomUUID(), name: name.trim(), description }).select().single();
  if (error) return res.status(500).json({ message: "Erro ao criar categoria.", detail: error.message });
  return res.status(201).json(data);
});

app.put("/categorias/:id", async (req, res) => {
  const { name, description } = req.body;
  const changes: { name?: string; description?: string | null } = {};
  if (name !== undefined) {
    if (typeof name !== "string" || !name.trim()) return res.status(400).json({ message: "Nome da categoria inválido." });
    changes.name = name.trim();
  }
  if (description !== undefined) changes.description = description;
  const { data, error } = await supabase.from("categories").update(changes).eq("id", req.params.id).select().maybeSingle();
  if (error) return res.status(500).json({ message: "Erro ao atualizar categoria.", detail: error.message });
  if (!data) return res.status(404).json({ message: "Categoria não encontrada." });
  return res.status(200).json(data);
});

app.delete("/categorias/:id", async (req, res) => {
  const { data, error } = await supabase.from("categories").delete().eq("id", req.params.id).select("id").maybeSingle();
  if (error) return res.status(500).json({ message: "Erro ao remover categoria.", detail: error.message });
  if (!data) return res.status(404).json({ message: "Categoria não encontrada." });
  return res.status(200).json({ message: "Categoria removida com sucesso." });
});

app.get("/produtos", async (req, res) => {
  let query = supabase.from("products").select("*, categories(id, name)").order("name");
  if (typeof req.query.categoryId === "string") query = query.eq("category_id", req.query.categoryId);
  const { data, error } = await query;
  if (error) return res.status(500).json({ message: "Erro ao buscar produtos.", detail: error.message });
  return res.status(200).json(data);
});

app.get("/produtos/:id", async (req, res) => {
  const { data, error } = await supabase.from("products").select("*, categories(id, name)").eq("id", req.params.id).maybeSingle();
  if (error) return res.status(500).json({ message: "Erro ao buscar produto.", detail: error.message });
  if (!data) return res.status(404).json({ message: "Produto não encontrado." });
  return res.status(200).json(data);
});

app.post("/produtos", async (req, res) => {
  const { categoryId, name, description, price } = req.body;
  if (!categoryId || typeof name !== "string" || !name.trim() || !Number.isFinite(price) || price < 0) {
    return res.status(400).json({ message: "Informe categoria, nome e preço válido para o produto." });
  }
  const { data, error } = await supabase.from("products").insert({ id: randomUUID(), category_id: categoryId, name: name.trim(), description, price }).select().single();
  if (error) return res.status(500).json({ message: "Erro ao criar produto.", detail: error.message });
  return res.status(201).json(data);
});

app.put("/produtos/:id", async (req, res) => {
  const { categoryId, name, description, price } = req.body;
  const changes: { category_id?: string; name?: string; description?: string | null; price?: number } = {};
  if (categoryId !== undefined) changes.category_id = categoryId;
  if (name !== undefined) {
    if (typeof name !== "string" || !name.trim()) return res.status(400).json({ message: "Nome do produto inválido." });
    changes.name = name.trim();
  }
  if (description !== undefined) changes.description = description;
  if (price !== undefined) {
    if (!Number.isFinite(price) || price < 0) return res.status(400).json({ message: "Preço inválido." });
    changes.price = price;
  }
  const { data, error } = await supabase.from("products").update(changes).eq("id", req.params.id).select().maybeSingle();
  if (error) return res.status(500).json({ message: "Erro ao atualizar produto.", detail: error.message });
  if (!data) return res.status(404).json({ message: "Produto não encontrado." });
  return res.status(200).json(data);
});

app.delete("/produtos/:id", async (req, res) => {
  const { data, error } = await supabase.from("products").delete().eq("id", req.params.id).select("id").maybeSingle();
  if (error) return res.status(500).json({ message: "Erro ao remover produto.", detail: error.message });
  if (!data) return res.status(404).json({ message: "Produto não encontrado." });
  return res.status(200).json({ message: "Produto removido com sucesso." });
});

app.get("/pedidos", async (_req, res) => {
  const { data, error } = await supabase.from("orders").select("*, order_items(*)").order("created_at", { ascending: false });
  if (error) return res.status(500).json({ message: "Erro ao buscar pedidos.", detail: error.message });
  return res.status(200).json(data);
});

app.post("/pedidos", async (req, res) => {
  const { customerName, items } = req.body;
  if (typeof customerName !== "string" || !customerName.trim() || !Array.isArray(items) || items.length === 0) {
    return res.status(400).json({ message: "Informe o nome do cliente e ao menos um item." });
  }
  const normalized = items.map((item: { productId?: string; quantity?: number }) => ({ product_id: item.productId, quantity: item.quantity }));
  if (normalized.some((item) => typeof item.product_id !== "string" || !Number.isInteger(item.quantity) || (item.quantity ?? 0) < 1)) {
    return res.status(400).json({ message: "Cada item deve ter productId e quantidade inteira maior que zero." });
  }
  const { data, error } = await supabase.rpc("create_order", { p_customer_name: customerName.trim(), p_items: normalized });
  if (error) return res.status(400).json({ message: "Não foi possível criar o pedido.", detail: error.message });
  return res.status(201).json(data);
});

export default app;
