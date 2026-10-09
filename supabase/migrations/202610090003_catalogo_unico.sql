create unique index if not exists products_category_name_unique_idx
  on public.products(category_id, name);
