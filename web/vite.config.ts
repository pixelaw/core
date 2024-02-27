import path from "path"
import react from "@vitejs/plugin-react"
import { defineConfig } from "vite"
import ImportMetaEnvPlugin from "@import-meta-env/unplugin";
import wasm from 'vite-plugin-wasm'
import topLevelAwait from "vite-plugin-top-level-await";

export default defineConfig({
  build: {
    sourcemap: true
  },
  plugins: [
    react(),
    wasm(),
    topLevelAwait(),
    ImportMetaEnvPlugin.vite({
      example: ".env.example",
    }),
  ],
  server: {
    proxy: {
      '/api': {
        target: 'http://localhost:3000/',
        changeOrigin: true,
      },
      '/world': {
        target: 'http://localhost:3000/',
        changeOrigin: true,
      },
      '/manifests': {
        target: 'http://localhost:3000/',
        changeOrigin: true,
      },
    },
  },
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src"),
    },
  },

})
