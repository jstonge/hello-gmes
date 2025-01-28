---
toc: false
theme: "air"
---

<div class="hero">
  <h1>Hello Group-based modeling</h1>
  <h2>We study how group-based models impact how we think about all sorts of contagion.</h2>
  <a href="https://mocs.observablehq.cloud/mocs-fall-2024/getting-started" target="_blank">Get started<span style="display: inline-block; margin-left: 0.25rem;">→</span></a>
</div>

<div class="gallery grid grid-cols-3" style="grid-auto-rows;">
    <a href="https://joint-lab.observablehq.cloud/hello-gmes/models/source-sink" target="_blank">
    <picture>
        <source srcset="./assets/inst-localization.webp" media="(prefers-color-scheme: dark)">
        <img src="./assets/inst-localization.webp">
    </picture>
    <div class="small arrow">💡 Source-sink</div>
    </a>
    <a href="https://joint-lab.observablehq.cloud/hello-gmes/models/call-for-action" target="_blank">
    <picture>
        <source srcset="./assets/call-for-action.webp" media="(prefers-color-scheme: dark)">
        <img src="./assets/call-for-action.webp">
    </picture>
    <div class="small arrow">💡 Call for action</div>
    </a>
    <a href="https://joint-lab.observablehq.cloud/hello-gmes/models/model-3" target="_blank">
    <picture>
        <source srcset="./assets/model-3.webp" media="(prefers-color-scheme: dark)">
        <img src="./assets/model-3.webp">
    </picture>
    <div class="small arrow">💡 Model 3 (WIP)</div>
    </a>
</div>



<style>
    
    /* Gallery */

    .gallery {
        max-width: calc(1200px + 2rem);
    }

    .gallery a {
        display: flex;
        flex-direction: column;
        align-items: center;
        gap: 0.5rem;
    }

    .gallery img {
        width: 100%; /* Ensures the image takes up the full width of the container */
        height: 300px; /* Sets a fixed height for all images */
        object-fit: cover; /* Maintains aspect ratio while ensuring the image covers the entire area */
        border-radius: 8px;
        box-shadow: 0 0 0 0.75px rgba(128, 128, 128, 0.2), 0 6px 12px 0 rgba(0, 0, 0, 0.2);
        aspect-ratio: 2500 / 1900; /* Can be removed if you're using fixed dimensions */
    }

    @media (prefers-color-scheme: dark) {
        .gallery img {
            box-shadow: 0 0 0 0.75px rgba(128, 128, 128, 0.2), 0 6px 12px 0 rgba(0, 0, 0, 0.4);
            }
        }
        .gallery a:not(:hover, :focus) {
            color: var(--theme-foreground-muted);
        }

        .gallery a:hover img,
        .gallery a:focus img {
            box-shadow: 0 0 0 0.75px var(--theme-foreground-focus), 0 6px 12px 0 rgba(0, 0, 0, 0.2);
        }

        .gallery figcaption {
            font-size: 12px;
            color: inherit;
        }

        .arrow {
            font-weight: 500;
        }

        .arrow::after {
            content: "→";
            display: inline-block;
            margin-left: 0.25rem;
        }

.hero {
  display: flex;
  flex-direction: column;
  align-items: center;
  font-family: var(--sans-serif);
  margin: 0rem 0 4rem;
  text-wrap: balance;
  text-align: center;
}

.hero h1 {
  margin: 2rem 0;
  max-width: none;
  font-size: 8vw;
  font-weight: 800;
  line-height: 1;
  background: linear-gradient(30deg, var(--theme-foreground-focus), currentColor);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

.hero h2 {
  margin: 0;
  max-width: none;
  font-size: 20px;
  font-style: initial;
  font-weight: 500;
  line-height: 1.5;
  color: var(--theme-foreground-muted);
}


/* Gallery */

.gallery {
  max-width: calc(1200px + 2rem);
}

.gallery a {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.5rem;
}

.gallery img {
  max-width: 100%;
  border-radius: 8px;
  box-shadow: 0 0 0 0.75px rgba(128, 128, 128, 0.2), 0 6px 12px 0 rgba(0, 0, 0, 0.2);
  aspect-ratio: 2500 / 1900;
}

@media (prefers-color-scheme: dark) {
  .gallery img {
    box-shadow: 0 0 0 0.75px rgba(128, 128, 128, 0.2), 0 6px 12px 0 rgba(0, 0, 0, 0.4);
  }
}

.gallery a:not(:hover, :focus) {
  color: var(--theme-foreground-muted);
}

.gallery a:hover img,
.gallery a:focus img {
  box-shadow: 0 0 0 0.75px var(--theme-foreground-focus), 0 6px 12px 0 rgba(0, 0, 0, 0.2);
}

.gallery figcaption {
  font-size: 12px;
  color: inherit;
}

.arrow {
  font-weight: 500;
}

.arrow::after {
  content: "→";
  display: inline-block;
  margin-left: 0.25rem;
}


@media (min-width: 640px) {
  .hero h1 {
    font-size: 90px;
  }
}


.text-align-center {
  text-align: center;
}

img.centered {
  display: block;
  margin-left: auto;
  margin-right: auto;
}


</style>
