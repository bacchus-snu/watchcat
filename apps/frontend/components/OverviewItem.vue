<template>
  <div class="overview-item">
    <h3 class="overview-title">{{ title }}</h3>
    <div class="overview-value">{{ value }}</div>
  </div>
</template>

<script>
export default {
  props: ["title", "value"]
}
</script>

<style>
.overview-item {
  width: 150px;
  height: 150px;
  text-align: center;
  border: 1px solid rgb(230, 230, 230);
  margin: 0px;
}

.overview-title {
  padding: 20px 0;
  margin: 0;
}

.overview-value {
  font-size: 32px;
  padding: 10px;

}
</style>
