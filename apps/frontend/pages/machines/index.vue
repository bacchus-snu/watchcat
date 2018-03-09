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
          machine_list: res.sort(function(a,b) {
            if (a.name > b.name)return 1
            else if (a.name < b.name)return -1
            else return 0
          })
        }
      })
  },
  components: {
    MachineRow
  }
}
</script>
