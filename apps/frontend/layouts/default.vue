<template>
  <el-container>
    <el-header>
      <div class="header-container">
        <el-menu :router="true" :default-active="$route.path" class="menu-bar" mode="horizontal">
        <h1>
          <router-link to="/">
            WatchCat
          </router-link>
        </h1>
          <el-menu-item index="/machines">Machines</el-menu-item>
        </el-menu>
      </div>
    </el-header>
    <el-main>
      <nuxt/>
    </el-main>
  </el-container>
</template>

<style>
.header-container {
  display: -webkit-flex;
  display: flex;
  height: 61px;
}

h1 {
  float: left;
  height: 60px;
  margin: 0;
  padding: 0;
  line-height: 60px;
  font-size: 32px;
}

.menu-bar {
  float: right;
  flex: 1;
}
</style>
