<template>
  <el-container>
    <el-header height="100px">
      <h1>WatchCat</h1>
      <el-menu :router="true" :default-active="$route.path" class="menu-bar" mode="horizontal">
        <el-menu-item index="/machines">Machines</el-menu-item>
        <el-menu-item index="/tags">Tags</el-menu-item>
      </el-menu>
    </el-header>
    <el-main>
      <nuxt/>
    </el-main>
  </el-container>
</template>
