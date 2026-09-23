const menuButton = document.querySelector('.menu-button');
const navigation = document.querySelector('.site-nav');
const languageToggle = document.querySelector('.language-toggle');

const translations = {
  es: {
    "nav-work": "Trayectoria",
    "nav-expertise": "Especialidad",
    "nav-credentials": "Credenciales",
    "nav-contact": "Contacto",
    "hero-title": "De ideas complejas<br />a <em>sistemas cloud</em><br />que llegan a produccion.",
    "hero-summary": "Soy Federico, Arquitecto de Soluciones Cloud e Ingeniero de IA. Asumo responsabilidad desde la primera decision de arquitectura hasta la implementacion, la resolucion de problemas y la entrega.",
    "hero-action": "Conoce mi historia <span aria-hidden=\"true\">↓</span>",
    "current-label": "Actualmente",
    "current-role": "Cloud Engineer en Globant",
    "story-eyebrow": "01 / El punto de partida",
    "story-title": "La curiosidad se volvio<br /><em>practica.</em>",
    "story-one": "La tecnologia capto mi atencion desde temprano. Aprender a programar por mi cuenta y administrar servidores de Minecraft me introdujo a la infraestructura, la automatizacion, la resolucion de problemas y el placer de crear sistemas utiles para las personas.",
    "story-two": "Esa curiosidad se convirtio en una carrera en ingenieria cloud: tomar ideas ambiguas, definir una direccion tecnica y colaborar con equipos de producto e ingenieria hasta que exista una solucion lista para produccion.",
    "story-note": "La mentalidad: mejora continua, errores utiles y adaptacion constante.",
    "experience-eyebrow": "02 / Trayectoria",
    "experience-title": "Sistemas con<br /><em>proposito.</em>",
    "globant-date": "2023 — actualidad",
    "cloud-engineer": "Cloud Engineer",
    "globant-description": "Diseno soluciones cloud impulsadas por IA, sistemas RAG y entornos Azure multirregion. Mi trabajo abarca Azure OpenAI, AI Search, FastAPI, Terraform, API Management y automatizacion CI/CD.",
    "endava-description": "Avance desde practicante hasta tecnico senior mientras automatizaba infraestructura, operaba microservicios en Kubernetes y entregaba entornos seguros en Azure y AWS.",
    "education-label": "Educacion",
    "education-degree": "Ingenieria de Software",
    "education-date": "Desde 2018",
    "practice-eyebrow": "03 / Especialidad",
    "practice-title": "El trabajo esta<br /><em>en los detalles.</em>",
    "architecture-title": "Arquitectura cloud",
    "architecture-description": "Sistemas multirregion, redes privadas, identidad, observabilidad y gobierno en Azure y AWS.",
    "ai-title": "IA aplicada",
    "ai-description": "Experiencias de IA fundamentadas que combinan embeddings, recuperacion, ingesta de datos y diseno de aplicaciones practicas.",
    "delivery-title": "Entrega de plataforma",
    "delivery-description": "Despliegues repetibles, operaciones de API y automatizacion que facilitan la construccion y operacion de entornos.",
    "credentials-eyebrow": "04 / Credenciales",
    "credentials-title": "Un solo muro.<br /><em>Cada hito.</em>",
    "credentials-description": "Dieciseis credenciales que reflejan el camino en arquitectura cloud, DevOps, contenedores, datos e IA. Cada parte del recorrido pertenece aqui.",
    "contact-eyebrow": "05 / Contacto",
    "contact-title": "Hagamos algo<br /><em>util.</em>"
  }
};

const originals = new Map(
  [...document.querySelectorAll('[data-i18n], [data-i18n-html]')].map((element) => [
    element,
    element.dataset.i18nHtml ? element.innerHTML : element.textContent,
  ]),
);

function setLanguage(language) {
  const dictionary = language === 'es' ? translations.es : {};

  originals.forEach((original, element) => {
    const key = element.dataset.i18nHtml ?? element.dataset.i18n;
    const translated = dictionary[key] ?? original;

    if (element.dataset.i18nHtml) {
      element.innerHTML = translated;
    } else {
      element.textContent = translated;
    }
  });

  document.documentElement.lang = language;
  document.title = language === 'es'
    ? 'Federico Nicolas Cabrera | Arquitecto de Soluciones Cloud'
    : 'Federico Nicolas Cabrera | Cloud Solutions Architect';

  if (languageToggle) {
    languageToggle.textContent = language === 'es' ? 'EN' : 'ES';
    languageToggle.setAttribute('aria-label', language === 'es' ? 'Switch to English' : 'Cambiar a espanol');
    languageToggle.setAttribute('aria-pressed', String(language === 'es'));
  }

  const url = new URL(window.location.href);
  if (language === 'es') {
    url.searchParams.set('lang', 'es');
  } else {
    url.searchParams.delete('lang');
  }
  window.history.replaceState(null, '', url);
}

languageToggle?.addEventListener('click', () => {
  setLanguage(document.documentElement.lang === 'es' ? 'en' : 'es');
});

setLanguage(new URLSearchParams(window.location.search).get('lang') === 'es' ? 'es' : 'en');

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