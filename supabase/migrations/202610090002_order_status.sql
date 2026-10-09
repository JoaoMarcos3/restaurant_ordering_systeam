create or replace function public.update_order_status(p_order_id uuid, p_new_status text)
returns jsonb
language plpgsql
security invoker
set search_path = public
as $$
declare
  current_order public.orders%rowtype;
begin
  select * into current_order
  from public.orders
  where id = p_order_id
  for update;

  if not found then raise exception 'Pedido não encontrado'; end if;
  if p_new_status not in ('recebido', 'preparando', 'saiu_para_entrega', 'concluido', 'cancelado') then
    raise exception 'Status inválido';
  end if;

  if not (
    (current_order.status = 'recebido' and p_new_status in ('preparando', 'cancelado')) or
    (current_order.status = 'preparando' and p_new_status in ('saiu_para_entrega', 'cancelado')) or
    (current_order.status = 'saiu_para_entrega' and p_new_status = 'concluido')
  ) then
    raise exception 'Transição de status não permitida: % -> %', current_order.status, p_new_status;
  end if;

  update public.orders set status = p_new_status where id = p_order_id returning * into current_order;
  return jsonb_build_object(
    'id', current_order.id,
    'customer_name', current_order.customer_name,
    'status', current_order.status,
    'total', current_order.total,
    'created_at', current_order.created_at,
    'items', coalesce((select jsonb_agg(to_jsonb(order_items)) from public.order_items where order_id = current_order.id), '[]'::jsonb)
  );
end;
$$;

revoke all on function public.update_order_status(uuid, text) from public, anon, authenticated;
grant execute on function public.update_order_status(uuid, text) to service_role;
