const menuButton = document.querySelector('.menu-button');
const navigation = document.querySelector('.site-nav');

menuButton?.addEventListener('click', () => {
  const isOpen = navigation.classList.toggle('is-open');
  menuButton.setAttribute('aria-expanded', String(isOpen));
});

navigation?.querySelectorAll('a').forEach((link) => link.addEventListener('click', () => {
  navigation.classList.remove('is-open');
  menuButton?.setAttribute('aria-expanded', 'false');
}));

const vendorMatches = {
  microsoft: ['microsoft', 'openhack'],
};

document.querySelectorAll('.vendor-tab').forEach((tab) => tab.addEventListener('click', () => {
  const vendor = tab.dataset.vendor;
  const matches = vendorMatches[vendor] ?? [vendor];

  document.querySelectorAll('.vendor-tab').forEach((item) => {
    const selected = item === tab;
    item.classList.toggle('is-active', selected);
    item.setAttribute('aria-selected', String(selected));
  });

  document.querySelectorAll('.credential-card').forEach((card) => {
    const visible = vendor === 'all' || matches.some((vendorClass) => card.classList.contains(vendorClass));
    card.hidden = !visible;
  });
}));

const observer = new IntersectionObserver((entries) => {
  entries.forEach((entry) => {
    if (entry.isIntersecting) {
      entry.target.classList.add('is-visible');
      observer.unobserve(entry.target);
    }
  });
}, { threshold: 0.12 });

document.querySelectorAll('.reveal').forEach((element) => observer.observe(element));
document.querySelector('#year').textContent = new Date().getFullYear();

const issuerIcons = {
  aws: { name: 'AWS', glyph: 'aws' },
  hashicorp: { name: 'HashiCorp', glyph: 'hc' },
  microsoft: { name: 'Microsoft', glyph: 'ms' },
  linux: { name: 'The Linux Foundation', glyph: 'lf' },
  openhack: { name: 'Microsoft OpenHack', glyph: 'oh' },
};

document.querySelectorAll('.credential-card').forEach((card) => {
  if (card.querySelector('.credential-badge')) return;
  const issuer = Object.entries(issuerIcons).find(([className]) => card.classList.contains(className))?.[1];
  if (!issuer) return;
  const icon = document.createElement('span');
  icon.className = 'credential-icon';
  icon.textContent = issuer.glyph;
  icon.setAttribute('role', 'img');
  icon.setAttribute('aria-label', `${issuer.name} icon`);
  card.prepend(icon);
});