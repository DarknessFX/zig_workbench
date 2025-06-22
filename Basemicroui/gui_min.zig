// Build using Zig 0.14.1

//=============================================================================
//#region MARK: GLOBAL
//=============================================================================
pub const mu = @cImport({
  @cInclude("microui.h");
});

pub fn present(ctx: *mu.mu_Context) void {
  mu.mu_begin(ctx);
  if (mu.mu_begin_window(ctx, "Sample Window", mu.mu_rect(350, 250, 300, 240)) != 0) {
    const cnt: *mu.mu_Container = mu.mu_get_current_container(ctx);
    cnt.rect.w = @max(cnt.rect.w, 240);
    cnt.rect.h = @max(cnt.rect.h, 300);

    mu.mu_layout_row(ctx, 2, &[_]c_int{ -70, -1 }, 0);
    _ = mu.mu_button_ex(ctx, "Submit", 0, mu.MU_OPT_ALIGNCENTER);
    mu.mu_end_window(ctx);
  }
  mu.mu_end(ctx);
}