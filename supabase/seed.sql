insert into public.categories (name, description)
values
  ('Pizzas', 'Pizzas tradicionais e especiais'),
  ('Bebidas', 'Bebidas para acompanhar o pedido'),
  ('Sobremesas', 'Sobremesas da casa')
on conflict (name) do update set description = excluded.description;

insert into public.products (category_id, name, description, price)
select c.id, p.name, p.description, p.price
from (values
  ('Pizzas', 'Margherita', 'Molho de tomate, mussarela e manjericão', 39.90::numeric),
  ('Pizzas', 'Calabresa', 'Calabresa fatiada, cebola e mussarela', 42.90::numeric),
  ('Bebidas', 'Refrigerante 2L', 'Refrigerante de dois litros', 12.00::numeric),
  ('Sobremesas', 'Pizza de chocolate', 'Chocolate cremoso e granulado', 36.90::numeric)
) as p(category_name, name, description, price)
join public.categories c on c.name = p.category_name
on conflict (category_id, name) do update
set description = excluded.description,
    price = excluded.price,
    available = true;
