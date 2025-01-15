// NOTE: Vulkan Validation Layer incomplete, 
//   I mess up when porting the callbacks and is not working.

const std = @import("std");
const vk = @cImport({
  @cInclude("vulkan.h");
});

pub const validation_layers = [_][*c]const u8{ "VK_LAYER_KHRONOS_validation" };
pub var debug_messenger: vk.VkDebugUtilsMessengerEXT = undefined;

fn vkcheck(result: vk.VkResult, comptime err_msg: []const u8) !void {
  if (result != vk.VK_SUCCESS) {
    std.io.getStdOut().writer().print("Vulkan error : {s}\n",  .{ err_msg }) catch unreachable;
    std.debug.print("Vulkan error : {s}\n", .{ err_msg });
    @panic(err_msg);
    //return error.VulkanError;
  }
}

pub fn checkExtensionProperties() !void {
  var extension_count: u32 = 0;
  try vkcheck(vk.vkEnumerateInstanceExtensionProperties(null, &extension_count, null), "Failed to enumerate instance extensions");
  std.debug.print("{d} extensions supported\n", .{ extension_count });

  const extensions = try std.heap.page_allocator.alloc(vk.VkExtensionProperties, extension_count);
  defer std.heap.page_allocator.free(extensions);
  try vkcheck(vk.vkEnumerateInstanceExtensionProperties(null, &extension_count, extensions.ptr), "Failed to get instance extensions");

  std.debug.print("Available extensions :\n", .{});
  for (extensions) |extension| {
    const extension_len = std.mem.indexOf(u8, extension.extensionName[0..], &[_]u8{0}) orelse 256;
    std.debug.print("  {s}\n", .{extension.extensionName[0..extension_len]});
  }
}

pub fn checkValidationLayerSupport() bool {
  var layer_count: u32 = 0;
  _ = vk.vkEnumerateInstanceLayerProperties(&layer_count, null);

  const available_layers = std.heap.page_allocator.alloc(vk.VkLayerProperties, layer_count) catch unreachable;
  defer std.heap.page_allocator.free(available_layers);
  _ = vk.vkEnumerateInstanceLayerProperties(&layer_count, available_layers.ptr);

  std.debug.print("Validation check, searching: \n", .{});
  for (validation_layers) |layer_name| {
    const layer_name_span = std.mem.span(layer_name);
    const layer_name_len = layer_name_span.len;
    std.debug.print("  {s}\nValidation properties list :\n", .{ layer_name_span });
    var found: bool = false;
    for (available_layers) |layer_properties| {
      std.debug.print("  {s}\n", .{ layer_properties.layerName });
      const prop_name_len = std.mem.indexOf(u8, layer_properties.layerName[0..], &[_]u8{0}) orelse 256;
      if (layer_name_len == prop_name_len) {
        std.debug.print("Found:\n  {s}\n", .{ &layer_properties.layerName });
        if (std.mem.eql(u8, layer_name_span, layer_properties.layerName[0..prop_name_len])) {
          found = true;
          break;
        }
      }
    }
    if (!found) return false;
  }
  return true;
}

// pub extern fn vkCreateDebugUtilsMessengerEXT(
//   instance: vk.VkInstance, 
//   pCreateInfo: *const vk.VkDebugUtilsMessengerCreateInfoEXT, 
//   pAllocator: ?*const vk.VkAllocationCallbacks, 
//   pDebugMessenger: *vk.VkDebugUtilsMessengerEXT)  callconv(.C) vk.VkResult;
pub fn CreateDebugUtilsMessengerEXT(instance: vk.VkInstance, pCreateInfo: *const vk.VkDebugUtilsMessengerCreateInfoEXT, pAllocator: ?*const vk.VkAllocationCallbacks, pDebugMessenger: *vk.VkDebugUtilsMessengerEXT) callconv(.C)  vk.VkResult {
  const func: vk.PFN_vkDebugUtilsMessengerCallbackEXT = @ptrCast(vk.vkGetInstanceProcAddr(instance, "vkCreateDebugUtilsMessengerEXT"));
  if (func) |f| {
    return f(instance, pCreateInfo, pAllocator, pDebugMessenger);
  } else {
    return vk.VK_ERROR_EXTENSION_NOT_PRESENT;
  }
}

// pub extern fn vkDestroyDebugUtilsMessengerEXT(
//   instance: vk.VkInstance, 
//   debugMessenger: vk.VkDebugUtilsMessengerEXT, 
//   pAllocator: ?*const vk.VkAllocationCallbacks) void;
pub fn DestroyDebugUtilsMessengerEXT(instance: vk.VkInstance, debugMessenger: vk.VkDebugUtilsMessengerEXT, pAllocator: ?*const vk.VkAllocationCallbacks) callconv(.C) void {
  _ = debugMessenger; _ = pAllocator;
  const func = vk.vkGetInstanceProcAddr(instance, "vkDestroyDebugUtilsMessengerEXT");
  if (func) |f| {
    f(); //f(instance, debugMessenger, pAllocator);
  }
}

pub fn populateDebugMessengerCreateInfo(createInfo: *vk.VkDebugUtilsMessengerCreateInfoEXT) void {
  createInfo.* = vk.VkDebugUtilsMessengerCreateInfoEXT{
    .sType = vk.VK_STRUCTURE_TYPE_DEBUG_UTILS_MESSENGER_CREATE_INFO_EXT,
    .pNext = null,
    .flags = 0,
    .messageSeverity =
      vk.VK_DEBUG_UTILS_MESSAGE_SEVERITY_VERBOSE_BIT_EXT |
      vk.VK_DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT |
      vk.VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT,
    .messageType = 
      vk.VK_DEBUG_UTILS_MESSAGE_TYPE_GENERAL_BIT_EXT |
      vk.VK_DEBUG_UTILS_MESSAGE_TYPE_VALIDATION_BIT_EXT |
      vk.VK_DEBUG_UTILS_MESSAGE_TYPE_PERFORMANCE_BIT_EXT,
    .pfnUserCallback = debugCallback,
    .pUserData = null,
  };
}

pub fn setupDebugMessenger(instance: vk.VkInstance) !void {
  //TODO: try to make this work, NOTE: enable at deinit too.
  // https://github.com/Overv/VulkanTutorial/blob/main/code/02_validation_layers.cpp
  _ = instance;
  return;

  // var createInfo: vk.VkDebugUtilsMessengerCreateInfoEXT = undefined;
  // populateDebugMessengerCreateInfo(&createInfo);
  // try vkcheck(CreateDebugUtilsMessengerEXT(instance, &createInfo, null, &debug_messenger), 
  //   "Failed to create debug utils messenger extension.");
}

fn debugCallback (
  messageSeverity: vk.VkDebugUtilsMessageSeverityFlagBitsEXT,
  messageType: vk.VkDebugUtilsMessageTypeFlagsEXT,
  pCallbackData: [*c]const vk.VkDebugUtilsMessengerCallbackDataEXT,
  pUserData: ?*anyopaque,
) callconv(.C) vk.VkBool32 {

  if (messageSeverity >= vk.VK_DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT) {
    std.debug.print("Validation layer :\n severity : {any}\n type : {any}\n callback_data: {any}\n message : {any}\n", .{
      messageSeverity, messageType, pCallbackData.*.pMessage, pUserData });
  }  
  return vk.VK_FALSE;
}