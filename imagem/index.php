<?php
$pdo = new PDO("mysql:host=localhost;dbname=ecovir28_mackai;charset=utf8mb4", "ecovir28_mackai", "WQMla7~i##8Z", [
    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION, 
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC, 
    PDO::ATTR_EMULATE_PREPARES => false
]);

$id = 1;

$stmt = $pdo -> prepare("SELECT E.`id`, E.`grupo`, E.`periodo`, E.`data`, E.`nome`, E.`texto`, E.`video`, G.`nome` AS `grupo_nome`, P.`nome` AS `periodo_nome` FROM `encontro` E LEFT JOIN `grupo` G ON E.`grupo` = G.`id` LEFT JOIN periodo P ON E.`periodo` = P.`id` WHERE E.`id`=:id");
$stmt -> bindValue(':id', $id, PDO::PARAM_INT);
$stmt->execute();
$encontro = $stmt->fetch(PDO::FETCH_ASSOC);

$stmt = $pdo -> prepare("SELECT `id`, `nome`, `data` FROM `encontro` WHERE `grupo`=:grupo AND `periodo`=:periodo ORDER BY `id` ASC");
$stmt -> bindValue(':grupo', $encontro['grupo'], PDO::PARAM_INT);
$stmt -> bindValue(':periodo', $encontro['periodo'], PDO::PARAM_INT);
$stmt->execute();
$encontros = $stmt->fetchAll(PDO::FETCH_ASSOC);
?>

<!doctype html>
<html lang="pt-BR">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>MACK·AI — <?=$encontro['grupo_nome']?></title>
<style>
  :root{
    --red-900:#c63226;
    --red-800:#d14236;
    --red-700:#e14b3e;
    --red-600:#ef5244;
    --red-500:#f3584a;
    --bg:#f7f7f7;
    --card:#ffffff;
    --text:#1d1d1f;
    --muted:#6b7280;
    --radius:14px;
    --shadow:0 6px 24px rgba(0,0,0,.08);
  }
  *{box-sizing:border-box}
  html,body{height:100%}
  body{
    margin:0;
    font:16px/1.45 system-ui, -apple-system, Segoe UI, Roboto, Ubuntu, "Helvetica Neue", Arial, "Apple Color Emoji","Segoe UI Emoji";
    color:var(--text);
    background:
      radial-gradient(1200px 600px at -200px -100px, rgba(255,255,255,.18), rgba(255,255,255,0) 60%),
      linear-gradient(180deg, #e7473d, #cf3c30 40%, #c83529 100%);
    background-attachment: fixed;
  }

  /* Topbar */
  .topbar{
    position: sticky; top:0; z-index:20;
    display:flex; align-items:center; gap:20px;
    padding:16px 22px;
    background:linear-gradient(180deg, rgba(255,255,255,.06), rgba(255,255,255,.02));
    backdrop-filter: blur(6px);
  }
  .brand{
    display:flex; align-items:center; gap:12px; color:#fff; font-weight:800; letter-spacing:.3px;
  }
  .brand-badge{
    width:34px; height:34px; border-radius:50%;
    background: url('/mack-ai-logo.jpg') center/cover no-repeat;
    box-shadow:0 2px 10px rgba(0,0,0,.12);
  }
  .brand span{font-size:20px}
  .search{
    flex:1; max-width:680px; position:relative;
  }
  .search input{
    width:100%; height:42px; border:none; outline: none;
    border-radius:999px; padding:0 44px; color:#fff;
    background:rgba(255,255,255,.14);
  }
  .search input::placeholder{color:rgba(255,255,255,.8)}
  .search svg{position:absolute; left:14px; top:50%; transform:translateY(-50%); opacity:.9; fill:#fff}
  .actions{margin-left:auto; display:flex; gap:18px}
  .icon-btn{
    width:34px; height:34px; display:grid; place-items:center; border-radius:999px;
    background:rgba(255,255,255,.16); cursor:pointer;
    transition:transform .08s ease, background .2s ease;
  }
  .icon-btn:hover{background:rgba(255,255,255,.25); transform: translateY(-1px)}
  .icon-btn svg{fill:#fff}

  /* Layout */
  .page{
    max-width:1150px; margin:14px auto 32px; padding:0 16px;
  }
  .shell{
    display:grid; grid-template-columns: 280px 1fr; gap:18px;
    background:rgba(255,255,255,.06); border-radius:var(--radius);
    padding:0; box-shadow: var(--shadow);
  }

  /* Sidebar */
  .sidebar{
    background:#fff; border-top-left-radius:var(--radius); border-bottom-left-radius:var(--radius);
    padding:14px; display:flex; flex-direction:column; gap:12px; min-height:560px;
  }
  .crumbs{
    display:flex; align-items:center; gap:10px; color:var(--muted); font-weight:600; margin:6px 2px 8px;
  }
  .back{display:grid; place-items:center; width:28px; height:28px; border-radius:8px; background:#f2f2f2}
  .group-title{white-space:nowrap; overflow:hidden; text-overflow:ellipsis; font-weight:700; color:#111}
  .list{display:flex; flex-direction:column; gap:8px; margin-top:8px}
  .item{
    border-radius:12px; padding:14px 12px; cursor:pointer; background:#fff; border:1px solid #efefef;
  }
  .item strong{display:block; font-weight:800; margin-bottom:4px}
  .item span{color:#444}
  .item:hover{border-color:#e4e4e4; background:#fcfcfc}
  .item.active{
    background:linear-gradient(180deg, #fbf1f0, #fff);
    border-color:#f2b7b2;
    box-shadow:inset 0 0 0 2px #f4c3bf;
  }

  /* Content */
  .content{
    background:#fff; border-top-right-radius:var(--radius); border-bottom-right-radius:var(--radius);
    padding:22px;
  }
  .player iframe {
    width: 100%;
    aspect-ratio: 16/9;
    border: none;
    border-radius: 14px;
  }
  .title{
    margin:22px 2px 6px; font-weight:900; letter-spacing:.2px; font-size: clamp(22px, 3vw, 32px);
  }
  .desc{
    color:#333; font-size:18px; max-width:920px;
  }

  /* Responsive */
  @media (max-width: 980px){
    .shell{grid-template-columns: 1fr}
    .sidebar{border-radius:var(--radius) var(--radius) 0 0; min-height:auto}
    .content{border-radius:0 0 var(--radius) var(--radius)}
  }
  @media (max-width: 620px){
    .player{height:220px}
    .actions{gap:10px}
    .brand span{display:none}
  }
  /* --- Overrides solicitadas --- */
  :root{ --topbar-h:64px; }
  .topbar{ min-height: var(--topbar-h); }
  .page{ max-width:none; margin:0; padding:0; }
  .shell{ width:100vw; border-radius:0; min-height: calc(100vh - var(--topbar-h)); }
  /* Hover com aumento nos botões do menu esquerdo */
  .item{ transition: transform .18s ease, box-shadow .2s ease, border-color .2s ease, background .2s ease; transform-origin: left center; }
  .item:hover{ transform: scale(1.04); box-shadow:0 8px 18px rgba(0,0,0,.08); }
</style>
</head>
<body>
  <!-- Top bar -->
  <header class="topbar" role="banner" aria-label="Barra superior">
    <div class="brand" aria-label="Marca">
      <div class="brand-badge" aria-hidden="true"></div>
      <span>MACK·AI</span>
    </div>

    <label class="search" aria-label="Buscar">
      <svg width="18" height="18" viewBox="0 0 24 24" aria-hidden="true">
        <path d="M10 4a6 6 0 104.472 10.061l4.733 4.734 1.414-1.414-4.734-4.733A6 6 0 0010 4zm0 2a4 4 0 110 8 4 4 0 010-8z"/>
      </svg>
      <input type="search" placeholder="Buscar..." aria-label="Campo de busca" />
    </label>

    <div class="actions" aria-label="Ações">
      <button class="icon-btn" aria-label="Notificações">
        <svg width="18" height="18" viewBox="0 0 24 24" aria-hidden="true">
          <path d="M12 22a2 2 0 002-2h-4a2 2 0 002 2zm6-6V11a6 6 0 10-12 0v5l-2 2v1h16v-1l-2-2z"/>
        </svg>
      </button>
      <button class="icon-btn" aria-label="Perfil">
        <svg width="18" height="18" viewBox="0 0 24 24" aria-hidden="true">
          <path d="M12 12a5 5 0 100-10 5 5 0 000 10zm0 2c-4.418 0-8 2.239-8 5v1h16v-1c0-2.761-3.582-5-8-5z"/>
        </svg>
      </button>
    </div>
  </header>

  <!-- Page -->
  <main class="page">
    <section class="shell" aria-label="Conteúdo">
      <!-- Sidebar -->
      <aside class="sidebar" aria-label="Lista de encontros">
        <div class="crumbs">
          <div class="back" title="Voltar" aria-hidden="true">
            <svg width="14" height="14" viewBox="0 0 24 24"><path d="M15 18l-6-6 6-6" fill="none" stroke="#111" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>
          </div>
          <div class="group-title"><?=$encontro['periodo_nome']?><br><?=$encontro['grupo_nome']?></div>
        </div>

        <div class="list" role="list">
<?php
    $i=1;
    $this_i = 0;
    foreach($encontros as $e){
        if($e['id']==$id):?>
          <div class="item active" role="listitem" aria-current="true">
            <strong>Encontro <?=$i?></strong>
            <i><?=date("d/m/y", strtotime($e['data']))?></i><br>
            <span><?=$e['nome']?></span>
          </div>
        <?php $this_i = $i; else:?>
          <div class="item" role="listitem">
            <strong>Encontro <?=$i?></strong>
            <i><?=date("d/m/y", strtotime($e['data']))?></i><br>
            <span><?=$e['nome']?></span>
          </div>
        <?php endif;
        $i++;
    }
?>
        </div>
      </aside>

      <!-- Content -->
      <section class="content">
        <div class="player">
          <iframe src="https://www.youtube.com/embed/<?=$encontro['video']?>" title="YouTube video player" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
        </div>

        <h1 class="title">Encontro <?=$this_i?> – <?=$encontro['nome'];?></h1>
        <h3><?=date("d/m/Y H\hi", strtotime($encontro['data']))?></h3>
        <p class="desc">
          <?=$encontro['texto']?>
        </p>
      </section>
    </section>
  </main>
</body>
</html>
