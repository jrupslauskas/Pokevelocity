// Toast notification handler
function initializeToasts() {
  const toasts = document.querySelectorAll('.toast[data-auto-dismiss="true"]');

  toasts.forEach(toast => {
    // Trigger show animation
    setTimeout(() => toast.classList.add('toast-show'), 10);

    // Auto dismiss after 5 seconds
    setTimeout(() => {
      toast.classList.add('toast-hide');
      setTimeout(() => toast.remove(), 300);
    }, 5000);
  });
}

// Initialize on page load
document.addEventListener('DOMContentLoaded', initializeToasts);

// Initialize on Turbo navigation (for subsequent page loads)
document.addEventListener('turbo:load', initializeToasts);

// Handle manual close button
window.closeToast = function(button) {
  const toast = button.closest('.toast');
  if (toast) {
    toast.classList.add('toast-hide');
    setTimeout(() => toast.remove(), 300);
  }
};
