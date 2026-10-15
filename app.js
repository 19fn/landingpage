const menuButton = document.querySelector('.menu-button');
const navigation = document.querySelector('.site-nav');
const languageToggle = document.querySelector('.language-toggle');

const translations = {
  es: {
    "nav-work": "Trayectoria",
    "nav-expertise": "Especialidad",
    "nav-credentials": "Credenciales",
    "nav-contact": "Contacto",
    "hero-title": "De ideas complejas<br />a <em>sistemas cloud</em><br />que llegan a producción.",
    "hero-summary": "Soy Federico, Arquitecto de Soluciones Cloud con experiencia en DevSecOps e ingeniería de IA. Diseño, automatizo y entrego plataformas seguras y escalables en AWS y Azure, integrando la seguridad y el cumplimiento en cada etapa.",
    "hero-action": "Conoce mi historia <span aria-hidden=\"true\">↓</span>",
    "current-label": "Actualmente",
    "current-role": "Cloud Solutions Architect en Ewents",
    "story-eyebrow": "01 / El punto de partida",
    "story-title": "La curiosidad se volvió<br /><em>práctica.</em>",
    "story-one": "La tecnología captó mi atención desde temprano. A los doce años ya había aprendido a programar por mi cuenta, y administrar servidores de Minecraft fue mi primera lección real de infraestructura, automatización, resolución de problemas y diseño de sistemas.",
    "story-two": "Esa curiosidad se convirtió en una carrera que comenzó en DevOps y evolucionó hacia la arquitectura cloud, la seguridad y la IA. Hoy me gusta hacerme cargo de los problemas de principio a fin: trabajo con equipos de producto e ingeniería para convertir ideas en software listo para producción, desde la primera decisión de arquitectura hasta la implementación, la resolución de problemas y la entrega.",
    "story-note": "La mentalidad: mejora continua, errores útiles y adaptación constante.",
    "experience-eyebrow": "02 / Trayectoria",
    "experience-title": "Sistemas con<br /><em>propósito.</em>",
    "ewents-date": "2025 — actualidad",
    "ewents-description": "Diseñé la arquitectura de una plataforma de cumplimiento continuo FedRAMP 20x que valida AWS, Okta, GitHub y otros servicios contra los controles NIST SP 800-53. Lideré el diseño de la landing zone multicuenta en AWS y de un servicio de identidad federada, e implementé autenticación zero-trust, aislamiento de datos multi-tenant y CI/CD DevSecOps con controles de seguridad automatizados.",
    "globant-date": "2023 — actualidad",
    "globant-tag": "GenAI empresarial",
    "globant-description": "Construí Terraform multirregión para una plataforma empresarial de GenAI en Azure con redes exclusivamente privadas, lideré versiones de una API RAG en producción y desarrollé una plataforma de análisis de uso y costos de IA. Administré más de 1.000 suscripciones de Azure y los planes ChatGPT Enterprise y Claude Enterprise de la organización.",
    "contract-label": "Contrato",
    "parallelstaff-description": "Migré aplicaciones .NET a contenedores, con más de 100 contenedores Windows en ejecución, y automaticé despliegues de clientes con Terraform. Mejoré la gestión de costos cloud, las redes y la observabilidad con Grafana.",
    "endava-description": "Avancé de practicante a técnico senior mientras automatizaba infraestructura con Terraform y pipelines CI/CD, operaba más de 25 microservicios en Kubernetes y entregaba entornos seguros en Azure y AWS.",
    "education-label": "Educación",
    "education-degree": "Ingeniería de Software",
    "practice-eyebrow": "03 / Especialidad",
    "practice-title": "El trabajo está<br /><em>en los detalles.</em>",
    "architecture-title": "Arquitectura cloud",
    "architecture-description": "Landing zones multicuenta en AWS, plataformas multirregión en Azure, redes privadas, identidad y servicios orientados a eventos, diseñados para escalar y gobernarse.",
    "devsecops-title": "DevSecOps y cumplimiento",
    "devsecops-description": "Seguridad integrada en la entrega: controles de seguridad en CI/CD, autenticación zero-trust, acceso de mínimo privilegio y cumplimiento como código alineado con FedRAMP 20x y NIST SP 800-53.",
    "ai-title": "IA aplicada",
    "ai-description": "Servicios RAG en producción, soluciones con Azure AI Foundry y análisis de uso y costos de IA, además de la administración de plataformas de IA empresariales en toda la organización.",
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