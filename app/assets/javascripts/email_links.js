// Turns contact_email_link placeholders into mailto links. The domain is
// stored reversed so the address never appears whole in the page's HTML.
document.addEventListener('turbolinks:load', function() {
  Array.prototype.forEach.call(document.querySelectorAll('.email-link[data-user]'), function(link) {
    var address = link.getAttribute('data-user') + '@' + link.getAttribute('data-domain').split('').reverse().join('');
    link.href = 'mailto:' + address;
    link.textContent = link.getAttribute('data-text') || address;
    link.removeAttribute('data-user');
  });
});
