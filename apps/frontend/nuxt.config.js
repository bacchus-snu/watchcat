module.exports = {
  /*
  ** Headers of the page
  */
  head: {
    title: 'watchcat-frontend',
    meta: [
      { charset: 'utf-8' },
      { name: 'viewport', content: 'width=device-width, initial-scale=1' },
      { hid: 'description', name: 'description', content: 'frontend application using watchcat api' }
    ],
    link: [
      { rel: 'icon', type: 'image/x-icon', href: '/favicon.ico' }
    ]
  },
  /*
  ** Customize the progress bar color
  */
  loading: { color: '#3B8070' },

  css: [
    'element-ui/lib/theme-chalk/reset.css',
    'element-ui/lib/theme-chalk/index.css'
  ],

  plugins: [
    '@/plugins/element-ui'
  ],

  modules: [
     '@nuxtjs/axios',
  ],

  axios: {
    proxy: true
  },

  proxy: {
    '/api/': 'http://watchcat.bacchus.snucse.org:10102'
  },
  /*
  ** Build configuration
  */
  build: {
    vendor: ['axios'],
    /*
    ** Run ESLint on save
    */
    extend (config, { isDev, isClient }) {
      if (isDev && isClient) {
        config.module.rules.push({
          enforce: 'pre',
          test: /\.(js|vue)$/,
          loader: 'eslint-loader',
          exclude: /(node_modules)/
        })
      }
    }
  }
}
