<template>
  <tr>
    <td>{{ info.name }}</td>
    <td>{{ info.host }}</td>
    <td>{{ metric.status }}</td>
    <td>{{ cpu }}</td>
  </tr>
</template>

<script>
export default {
  props: ['info', 'metric'],
  computed : {
    cpu () {
      if (this.metric.status == 'ok') {
        let cpu = this.metric.data.cpu
        return cpu.status == 'ok' ? cpu.data[0].usage.toFixed(2) + '%' : 'error'
      }
      return 'error'
    }
  },
  created() {
  }
}
</script>`
