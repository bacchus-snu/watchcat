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
import axios from 'axios'

export default {
  data () {
    machine_list: []
  },
  asyncData () {
    return axios.get('http://watchcat.bacchus.snucse.org:10102/api/machines')
      .then(function(res) {
        return {
          machine_list: res.data
        }
      })
  },
  components: {
    MachineRow
  }
}
</script>
