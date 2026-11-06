"use strict";

/* QuickClip PWA — save frequent texts, copy to clipboard with one tap. */

// ---------- Constants ----------

const STORAGE_KEY = "quickclip-data-v1";
const HINT_KEY = "quickclip-hint-dismissed";
const PALETTE = ["#0A84FF", "#FF9F0A", "#30D158", "#BF5AF2",
                 "#FF375F", "#64D2FF", "#FFD60A", "#8E8E93"];

// ---------- Inline SVG icons (Feather-style, stroke based) ----------

const ICONS = {
  plus: '<line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/>',
  sliders: '<line x1="4" y1="21" x2="4" y2="14"/><line x1="4" y1="10" x2="4" y2="3"/><line x1="12" y1="21" x2="12" y2="12"/><line x1="12" y1="8" x2="12" y2="3"/><line x1="20" y1="21" x2="20" y2="16"/><line x1="20" y1="12" x2="20" y2="3"/><line x1="1" y1="14" x2="7" y2="14"/><line x1="9" y1="8" x2="15" y2="8"/><line x1="17" y1="16" x2="23" y2="16"/>',
  search: '<circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/>',
  copy: '<rect x="9" y="9" width="13" height="13" rx="2" ry="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/>',
  edit: '<path d="M17 3a2.83 2.83 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5L17 3z"/>',
  trash: '<polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/>',
  clipboard: '<path d="M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2"/><rect x="8" y="2" width="8" height="4" rx="1" ry="1"/>',
  pin: '<path d="M19 21l-7-5-7 5V5a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2z"/>'
};

function svg(name, size, filled) {
  const attrs = 'viewBox="0 0 24 24" width="' + size + '" height="' + size +
    '" fill="' + (filled ? "currentColor" : "none") +
    '" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"';
  return '<svg ' + attrs + '>' + ICONS[name] + '</svg>';
}

// ---------- Seed data (mirrors the iOS app) ----------

function uid() {
  return (window.crypto && crypto.randomUUID)
    ? crypto.randomUUID()
    : "id-" + Math.random().toString(36).slice(2) + Date.now().toString(36);
}

function seedData() {
  const cats = [
    { id: uid(), name: "Personal", colorHex: "#0A84FF" },
    { id: uid(), name: "Work", colorHex: "#FF9F0A" },
    { id: uid(), name: "Finance", colorHex: "#30D158" },
    { id: uid(), name: "Links", colorHex: "#BF5AF2" }
  ];
  const ids = { Personal: cats[0].id, Work: cats[1].id, Finance: cats[2].id, Links: cats[3].id };
  const now = Date.now();
  const day = 86400000;
  const rows = [
    { title: "Email Address", content: "john.doe@example.com", categoryId: ids.Personal, isPinned: true, copyCount: 14, createdAt: now - 6 * day, lastCopiedAt: now - 3 * 3600000 },
    { title: "Phone Number", content: "+1 (555) 123-4567", categoryId: ids.Personal, isPinned: false, copyCount: 6, createdAt: now - 5 * day, lastCopiedAt: now - 2 * day },
    { title: "Shipping Address", content: "221B Baker Street\nLondon NW1 6XE\nUnited Kingdom", categoryId: ids.Personal, isPinned: false, copyCount: 3, createdAt: now - 4 * day, lastCopiedAt: null },
    { title: "Wi-Fi Password", content: "HomeNetwork-2024!", categoryId: ids.Personal, isPinned: false, copyCount: 9, createdAt: now - 3 * day, lastCopiedAt: now - 3600000 },
    { title: "Meeting Notes Template", content: "Agenda:\n- \n\nNotes:\n- \n\nAction items:\n- ", categoryId: ids.Work, isPinned: false, copyCount: 2, createdAt: now - 2 * day, lastCopiedAt: null },
    { title: "GitHub Profile", content: "https://github.com/yourusername", categoryId: ids.Links, isPinned: false, copyCount: 4, createdAt: now - day, lastCopiedAt: null },
    { title: "Bank Card Number", content: "**** **** **** 1234", categoryId: ids.Finance, isPinned: false, copyCount: 1, createdAt: now - 12 * 3600000, lastCopiedAt: null }
  ];
  return {
    snippets: rows.map(function (s) {
      return { id: uid(), updatedAt: s.createdAt, lastCopiedAt: s.lastCopiedAt, title: s.title, content: s.content, categoryId: s.categoryId, isPinned: s.isPinned, copyCount: s.copyCount, createdAt: s.createdAt };
    }),
    categories: cats,
    settings: { copyOnTap: true, showToast: true, sortOption: "dateAdded" }
  };
}

// ---------- State ----------

let state = null;
let activeFilter = null;   // category id or null
let searchTerm = "";
let editingId = null;      // snippet id being edited or null for new
let selectedColor = PALETTE[0];

function loadState() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (raw) state = JSON.parse(raw);
  } catch (e) { state = null; }
  if (!state || !Array.isArray(state.snippets) || !Array.isArray(state.categories)) {
    state = seedData();
    saveState();
  }
}

function saveState() {
  try { localStorage.setItem(STORAGE_KEY, JSON.stringify(state)); } catch (e) { /* ignore */ }
}

// ---------- Helpers ----------

function esc(s) {
  return String(s).replace(/[&<>"']/g, function (c) {
    return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c];
  });
}

function catById(id) {
  for (let i = 0; i < state.categories.length; i++) {
    if (state.categories[i].id === id) return state.categories[i];
  }
  return null;
}

function previewOf(content) {
  const t = String(content).trim();
  return t.length <= 80 ? (t || "Empty snippet") : t.slice(0, 80) + "…";
}

function relTime(ms) {
  if (!ms) return "never copied";
  const diff = Date.now() - ms;
  const min = Math.floor(diff / 60000);
  if (min < 1) return "just now";
  if (min < 60) return min + " min ago";
  const h = Math.floor(min / 60);
  if (h < 24) return h + " h ago";
  const d = Math.floor(h / 24);
  return d === 1 ? "1 day ago" : d + " days ago";
}

function sortedSnippets(items) {
  const arr = items.slice();
  const opt = state.settings.sortOption;
  if (opt === "title") {
    arr.sort(function (a, b) { return a.title.localeCompare(b.title, undefined, { sensitivity: "base" }); });
  } else if (opt === "mostCopied") {
    arr.sort(function (a, b) { return b.copyCount - a.copyCount; });
  } else if (opt === "recentlyCopied") {
    arr.sort(function (a, b) { return (b.lastCopiedAt || 0) - (a.lastCopiedAt || 0); });
  } else {
    arr.sort(function (a, b) { return b.createdAt - a.createdAt; });
  }
  return arr;
}

// ---------- Toast ----------

let toastTimer = null;

function toast(msg) {
  const el = document.getElementById("toast");
  el.textContent = msg;
  el.classList.add("show");
  if (toastTimer) clearTimeout(toastTimer);
  toastTimer = setTimeout(function () { el.classList.remove("show"); }, 1700);
}

function notify(msg) {
  if (state.settings.showToast) toast(msg);
}

// ---------- Clipboard ----------

async function writeClipboard(text) {
  try {
    await navigator.clipboard.writeText(text);
    return true;
  } catch (e) {
    try {
      const ta = document.createElement("textarea");
      ta.value = text;
      ta.style.position = "fixed";
      ta.style.opacity = "0";
      document.body.appendChild(ta);
      ta.focus();
      ta.select();
      const ok = document.execCommand("copy");
      ta.remove();
      return ok;
    } catch (e2) {
      return false;
    }
  }
}

async function copySnippet(id) {
  const s = state.snippets.find(function (x) { return x.id === id; });
  if (!s) return;
  const ok = await writeClipboard(s.content);
  if (ok) {
    s.copyCount += 1;
    s.lastCopiedAt = Date.now();
    saveState();
    renderList();
    notify("Copied to clipboard");
  } else {
    toast("Copy failed — open the snippet and copy manually");
  }
}

// ---------- Rendering ----------

function renderChips() {
  const el = document.getElementById("chips");
  let html = chipHtml(null, "All");
  for (let i = 0; i < state.categories.length; i++) {
    const c = state.categories[i];
    html += chipHtml(c.id, c.name, c.colorHex);
  }
  html += '<button class="chip" id="manageCats">+ Category</button>';
  el.innerHTML = html;

  el.querySelectorAll(".chip[data-id]").forEach(function (btn) {
    btn.addEventListener("click", function () {
      const id = btn.dataset.id || null;
      activeFilter = (activeFilter === id) ? null : id;
      renderChips();
      renderList();
    });
  });
  const manage = document.getElementById("manageCats");
  manage.addEventListener("click", function () { openCatManager(); });
}

function chipHtml(id, name, colorHex) {
  const active = (activeFilter === id) ? " active" : "";
  const dataId = id ? ' data-id="' + id + '"' : ' data-id=""';
  const dot = colorHex ? '<span class="chip-dot" style="background:' + esc(colorHex) + '"></span>' : "";
  return '<button class="chip' + active + '"' + dataId + ">" + dot + esc(name) + "</button>";
}

function rowHtml(s) {
  const cat = catById(s.categoryId);
  const color = cat ? cat.colorHex : "#8E8E93";
  const letter = cat ? cat.name.charAt(0).toUpperCase() : "•";
  const badge = '<span class="cat-badge" style="background:' + esc(color) + '">' + esc(letter) + "</span>";
  const pin = s.isPinned ? '<span class="pin">' + svg("pin", 13, true) + "</span>" : "";
  const title = '<div class="row-title">' + pin + "<span>" + esc(s.title) + "</span></div>";
  const prev = '<div class="row-preview">' + esc(previewOf(s.content)) + "</div>";
  const meta = '<div class="row-meta">' + s.copyCount +
    (s.copyCount === 1 ? " copy · " : " copies · ") + relTime(s.createdAt) + "</div>";
  const copyBtn = '<button class="row-btn" data-action="copy" aria-label="Copy">' + svg("copy", 19) + "</button>";
  const editBtn = '<button class="row-btn" data-action="edit" aria-label="Edit">' + svg("edit", 17) + "</button>";
  const delBtn = '<button class="row-btn danger" data-action="delete" aria-label="Delete">' + svg("trash", 17) + "</button>";
  return '<div class="row" data-id="' + s.id + '">' + badge +
    '<div class="row-main">' + title + prev + meta + "</div>" + copyBtn + editBtn + delBtn + "</div>";
}

function sectionHtml(title, items) {
  let html = '<div class="section-title">' + esc(title) + '</div><div class="card">';
  for (let i = 0; i < items.length; i++) html += rowHtml(items[i]);
  return html + "</div>";
}

function renderList() {
  const el = document.getElementById("list");
  let items = state.snippets;
  if (activeFilter) {
    items = items.filter(function (s) { return s.categoryId === activeFilter; });
  }
  const q = searchTerm.trim().toLowerCase();
  if (q) {
    items = items.filter(function (s) {
      return s.title.toLowerCase().indexOf(q) !== -1 ||
             s.content.toLowerCase().indexOf(q) !== -1;
    });
  }
  const sorted = sortedSnippets(items);
  if (sorted.length === 0) {
    let msg;
    if (q) msg = "No snippets match your search.";
    else if (activeFilter) msg = "No snippets in this category yet.";
    else msg = "No snippets yet. Tap + to add one.";
    el.innerHTML = '<div class="empty-state"><div class="big-icon">' + svg("copy", 52) +
      "</div><p>" + esc(msg) + "</p></div>";
    return;
  }
  const pinned = sorted.filter(function (s) { return s.isPinned; });
  const rest = sorted.filter(function (s) { return !s.isPinned; });
  let html = "";
  if (pinned.length) html += sectionHtml("Pinned", pinned);
  if (rest.length) html += sectionHtml(pinned.length ? "Others" : "All Snippets", rest);
  el.innerHTML = html;
}

function renderAll() {
  renderChips();
  renderList();
}

// ---------- Snippet editor ----------

function openEditor(id) {
  editingId = id || null;
  const dlg = document.getElementById("editor");
  const title = document.getElementById("editorTitle");
  const fTitle = document.getElementById("fTitle");
  const fContent = document.getElementById("fContent");
  const fCategory = document.getElementById("fCategory");
  const fPin = document.getElementById("fPin");

  title.textContent = id ? "Edit Snippet" : "New Snippet";

  let opts = '<option value="">None</option>';
  for (let i = 0; i < state.categories.length; i++) {
    const c = state.categories[i];
    opts += '<option value="' + c.id + '">' + esc(c.name) + "</option>";
  }
  fCategory.innerHTML = opts;

  if (id) {
    const s = state.snippets.find(function (x) { return x.id === id; });
    if (!s) return;
    fTitle.value = s.title;
    fContent.value = s.content;
    fCategory.value = s.categoryId || "";
    fPin.checked = !!s.isPinned;
  } else {
    fTitle.value = "";
    fContent.value = "";
    fCategory.value = "";
    fPin.checked = false;
  }
  dlg.showModal();
  fContent.focus();
}

function saveEditor() {
  const fTitle = document.getElementById("fTitle");
  const fContent = document.getElementById("fContent");
  const fCategory = document.getElementById("fCategory");
  const fPin = document.getElementById("fPin");

  const content = fContent.value;
  if (!content.trim()) {
    toast("Content cannot be empty");
    return;
  }
  let title = fTitle.value.trim();
  if (!title) title = content.trim().split(/\r?\n/)[0].slice(0, 32) || "Untitled";
  const categoryId = fCategory.value || null;

  if (editingId) {
    const s = state.snippets.find(function (x) { return x.id === editingId; });
    if (s) {
      s.title = title;
      s.content = content;
      s.categoryId = categoryId;
      s.isPinned = fPin.checked;
      s.updatedAt = Date.now();
    }
    notify("Snippet updated");
  } else {
    state.snippets.unshift({
      id: uid(), title: title, content: content, categoryId: categoryId,
      isPinned: fPin.checked, copyCount: 0, lastCopiedAt: null,
      createdAt: Date.now(), updatedAt: Date.now()
    });
    notify("Snippet added");
  }
  saveState();
  document.getElementById("editor").close();
  renderAll();
}

async function pasteFromClipboard() {
  const fTitle = document.getElementById("fTitle");
  const fContent = document.getElementById("fContent");
  try {
    const text = await navigator.clipboard.readText();
    if (text) {
      fContent.value = text;
      if (!fTitle.value.trim()) {
        fTitle.value = text.trim().split(/\r?\n/)[0].slice(0, 32);
      }
    } else {
      toast("Clipboard is empty");
    }
  } catch (e) {
    toast("Clipboard access denied — long-press the field to paste");
  }
}

function deleteSnippet(id) {
  const s = state.snippets.find(function (x) { return x.id === id; });
  if (!s) return;
  if (confirm('Delete "' + s.title + '"?')) {
    state.snippets = state.snippets.filter(function (x) { return x.id !== id; });
    saveState();
    renderAll();
    notify("Snippet deleted");
  }
}

// ---------- Category manager ----------

function openCatManager() {
  selectedColor = PALETTE[0];
  document.getElementById("catName").value = "";
  renderCatList();
  renderPalette();
  document.getElementById("catManager").showModal();
}

function renderCatList() {
  const el = document.getElementById("catList");
  let html = "";
  for (let i = 0; i < state.categories.length; i++) {
    const c = state.categories[i];
    const count = state.snippets.filter(function (s) { return s.categoryId === c.id; }).length;
    html += '<div class="cat-row">' +
      '<span class="cat-badge" style="background:' + esc(c.colorHex) + '">' +
      esc(c.name.charAt(0).toUpperCase()) + "</span>" +
      '<span class="name">' + esc(c.name) + "</span>" +
      '<span class="count">' + count + (count === 1 ? " snippet" : " snippets") + "</span>" +
      '<button class="row-btn danger" data-cat="' + c.id + '" aria-label="Delete category">' +
      svg("trash", 16) + "</button></div>";
  }
  if (!state.categories.length) {
    html = '<p class="about-line">No categories yet.</p>';
  }
  el.innerHTML = html;

  el.querySelectorAll("button[data-cat]").forEach(function (btn) {
    btn.addEventListener("click", function () {
      const cat = catById(btn.dataset.cat);
      if (!cat) return;
      if (!confirm('Delete category "' + cat.name + '"? Its snippets will be kept.')) return;
      state.categories = state.categories.filter(function (c) { return c.id !== cat.id; });
      state.snippets.forEach(function (s) {
        if (s.categoryId === cat.id) s.categoryId = null;
      });
      if (activeFilter === cat.id) activeFilter = null;
      saveState();
      renderCatList();
      renderAll();
    });
  });
}

function renderPalette() {
  const el = document.getElementById("catPalette");
  let html = "";
  for (let i = 0; i < PALETTE.length; i++) {
    const hex = PALETTE[i];
    const sel = hex === selectedColor ? " selected" : "";
    html += '<button class="swatch' + sel + '" data-hex="' + hex +
      '" style="background:' + hex + '" aria-label="Color ' + hex + '">' +
      (hex === selectedColor ? svg("pin", 0) : "") + "</button>";
  }
  el.innerHTML = html;
  el.querySelectorAll(".swatch").forEach(function (btn) {
    btn.addEventListener("click", function () {
      selectedColor = btn.dataset.hex;
      renderPalette();
    });
  });
}

function addCategory() {
  const input = document.getElementById("catName");
  const name = input.value.trim();
  if (!name) {
    toast("Enter a category name");
    return;
  }
  state.categories.push({ id: uid(), name: name, colorHex: selectedColor });
  input.value = "";
  saveState();
  renderCatList();
  renderAll();
  notify("Category added");
}

// ---------- Settings ----------

function syncSettingsUI() {
  document.getElementById("sCopyOnTap").checked = state.settings.copyOnTap;
  document.getElementById("sShowToast").checked = state.settings.showToast;
  document.getElementById("sSort").value = state.settings.sortOption;
  document.getElementById("aboutLine").textContent =
    "QuickClip v1.0 · " + state.snippets.length + " snippets · " +
    state.categories.length + " categories · stored in this browser";
}

function openSettings() {
  syncSettingsUI();
  document.getElementById("settings").showModal();
}

// ---------- Install hint ----------

function setupBanner() {
  let standalone = false;
  try {
    standalone = window.matchMedia("(display-mode: standalone)").matches ||
                 window.navigator.standalone === true;
  } catch (e) { standalone = false; }
  const dismissed = localStorage.getItem(HINT_KEY) === "1";
  if (!standalone && !dismissed) {
    document.getElementById("installBanner").hidden = false;
  }
}

// ---------- Wire-up ----------

function init() {
  loadState();

  // static icons
  document.getElementById("addBtn").innerHTML = svg("plus", 20);
  document.getElementById("settingsBtn").innerHTML = svg("sliders", 20);
  document.getElementById("pasteBtn").innerHTML = svg("clipboard", 16) + "Paste from Clipboard";
  document.querySelector(".search-icon").innerHTML = svg("search", 16);

  // search
  document.getElementById("search").addEventListener("input", function (e) {
    searchTerm = e.target.value;
    renderList();
  });

  // list interactions (event delegation)
  document.getElementById("list").addEventListener("click", function (e) {
    const btn = e.target.closest("button[data-action]");
    const row = e.target.closest(".row");
    if (!row) return;
    const id = row.dataset.id;
    if (btn) {
      if (btn.dataset.action === "copy") copySnippet(id);
      else if (btn.dataset.action === "edit") openEditor(id);
      else if (btn.dataset.action === "delete") deleteSnippet(id);
      return;
    }
    if (state.settings.copyOnTap) copySnippet(id);
    else openEditor(id);
  });

  // header
  document.getElementById("addBtn").addEventListener("click", function () { openEditor(null); });
  document.getElementById("settingsBtn").addEventListener("click", openSettings);

  // editor dialog
  document.getElementById("editorSave").addEventListener("click", saveEditor);
  document.getElementById("editorCancel").addEventListener("click", function () {
    document.getElementById("editor").close();
  });
  document.getElementById("pasteBtn").addEventListener("click", pasteFromClipboard);

  // category manager dialog
  document.getElementById("catClose").addEventListener("click", function () {
    document.getElementById("catManager").close();
  });
  document.getElementById("catAdd").addEventListener("click", addCategory);

  // settings dialog
  document.getElementById("settingsClose").addEventListener("click", function () {
    document.getElementById("settings").close();
  });
  document.getElementById("sCopyOnTap").addEventListener("change", function (e) {
    state.settings.copyOnTap = e.target.checked;
    saveState();
  });
  document.getElementById("sShowToast").addEventListener("change", function (e) {
    state.settings.showToast = e.target.checked;
    saveState();
  });
  document.getElementById("sSort").addEventListener("change", function (e) {
    state.settings.sortOption = e.target.value;
    saveState();
    renderList();
  });
  document.getElementById("sDeleteAll").addEventListener("click", function () {
    if (!confirm("Delete ALL snippets? This cannot be undone.")) return;
    state.snippets = [];
    saveState();
    renderAll();
    syncSettingsUI();
    toast("All snippets deleted");
  });
  document.getElementById("sReset").addEventListener("click", function () {
    if (!confirm("Reset everything back to the sample data?")) return;
    state = seedData();
    saveState();
    activeFilter = null;
    renderAll();
    syncSettingsUI();
    toast("App reset to defaults");
  });

  // banner
  setupBanner();
  document.getElementById("bannerClose").addEventListener("click", function () {
    document.getElementById("installBanner").hidden = true;
    try { localStorage.setItem(HINT_KEY, "1"); } catch (e) { /* ignore */ }
  });

  renderAll();

  // service worker (offline support)
  if ("serviceWorker" in navigator) {
    window.addEventListener("load", function () {
      navigator.serviceWorker.register("./sw.js").catch(function () { /* ignore */ });
    });
  }
}

document.addEventListener("DOMContentLoaded", init);
