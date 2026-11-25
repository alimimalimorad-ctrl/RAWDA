-- RAWDA security hardening: keep SECURITY DEFINER RPCs off the anonymous API.
revoke all on function public.is_platform_admin() from public, anon;
revoke all on function public.is_tenant_member(uuid) from public, anon;
revoke all on function public.has_tenant_role(uuid, public.app_role[]) from public, anon;
grant execute on function public.is_platform_admin() to authenticated;
grant execute on function public.is_tenant_member(uuid) to authenticated;
grant execute on function public.has_tenant_role(uuid, public.app_role[]) to authenticated;
revoke all on function public.handle_new_user() from public, anon, authenticated;
revoke all on function public.create_nursery_with_admin(text,text,text) from public, anon;
grant execute on function public.create_nursery_with_admin(text,text,text) to authenticated;
revoke all on function public.can_access_child(uuid,uuid) from public, anon;
revoke all on function public.can_access_classroom(uuid,uuid) from public, anon;
grant execute on function public.can_access_child(uuid,uuid) to authenticated;
grant execute on function public.can_access_classroom(uuid,uuid) to authenticated;
revoke all on function public.add_existing_teacher(uuid,text,text,text,uuid) from public, anon;
revoke all on function public.link_existing_parent(uuid,uuid,text,text) from public, anon;
grant execute on function public.add_existing_teacher(uuid,text,text,text,uuid) to authenticated;
grant execute on function public.link_existing_parent(uuid,uuid,text,text) to authenticated;
revoke all on function public.link_child_by_code(text,text) from public, anon;
revoke all on function public.review_parent_link_request(uuid,boolean) from public, anon;
grant execute on function public.link_child_by_code(text,text) to authenticated;
grant execute on function public.review_parent_link_request(uuid,boolean) to authenticated;
alter default privileges for role postgres in schema public
  revoke execute on functions from anon, authenticated, public;
