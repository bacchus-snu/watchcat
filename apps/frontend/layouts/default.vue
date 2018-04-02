<template>
  <el-container>
    <el-header>
      <div class="header-container">
        <h1>
          <router-link to="/">{{ this.windowWidth > 768 ? "WatchCat" : "WC" }}</router-link>
        </h1>
        <div class="nav-container">
          <div class="nav-item">
            <p><router-link to="/machines">Machines</router-link></p>
          </div>
          <div class="nav-item">
            <p><router-link to="/command">Command</router-link></p>
          </div>
        </div>
      </div>
    </el-header>
    <el-main>
      <div class="main-container">
        <nuxt/>
      </div>
    </el-main>
  </el-container>
</template>

<script>
export default {
  data () {
    return {
      windowWidth: 1920
    }
  },

  beforeMount () {
    this.windowWidth = window.innerWidth
    window.addEventListener('resize', this.updateWidth)
  },

  beforeDestroy () {
    window.removeEventListener('resize', this.updateWidth)
  },

  methods: {
    updateWidth () {
      this.windowWidth = window.innerWidth
    }
  }
}
</script>

<style>
.el-header {
  border-bottom: 1px solid rgb(230,230,230);
}

.header-container {
  display: -webkit-flex;
  display: flex;
  height: 60px;
  max-width: 1200px;
  margin-left: auto;
  margin-right: auto;
}

.header-container h1 {
  margin-right: 40px;
}

.nav-container {
  display: flex;
}

.nav-item {
  margin: 0 10px;
  font-size: 18px;
  text-align: center;
}

.nav-item a {
  color: black;
}

.nav-item p {
  padding: 14px 0;
}

h1 {
  float: left;
  height: 60px;
  margin: 0;
  padding: 0;
  line-height: 60px;
  font-size: 32px;
}

.main-container {
  max-width: 1200px;
  margin-left: auto;
  margin-right: auto;
}

.el-main {
  padding: 20px 10px;
}
</style>
