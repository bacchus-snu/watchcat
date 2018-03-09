<template>
  <div>
    <p>Machines page</p>
    <table id='machines-table'>
      <thead>
        <tr>
          <th>name</th>
          <th>host</th>
        </tr>
      </thead>
      <tbody>
        <tr is='machine-row'
          v-for='machine in machine_list'
          :info='machine'
          :key='machine.name'
        ></tr>
      </tbody>
    </table>
  </div>
</template>

<script>
import MachineRow from '~/components/MachineRow.vue'

export default {
  data () {
    machine_list: []
  },
  asyncData ({ app }) {
    return app.$axios.$get('/api/machines')
      .then(function(res) {
        return {
          machine_list: res
        }
      })
  },
  components: {
    MachineRow
  }
}
</script>
