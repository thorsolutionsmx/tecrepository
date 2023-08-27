metadata datoproyecto = {
  name: 'tecmont'
  description: 'se crea una serie de recursos para demo de bicep'
  version: '1.0.0'
}
param ubicacion string = 'eastus'



module recloganalitics 'modules/operational-insights/workspace/main.bicep' ={
     name:'loganalitdeploy0001'
     params:{
         name:'logmianalitica'
         location:ubicacion
     }
}


module recappinsight 'modules/insights/component/main.bicep' ={
     name:'appinsightdeploy0001'
     params:{
         name: 'appmisinsights'
         location: ubicacion
         workspaceResourceId: recloganalitics.outputs.resourceId
          applicationType: 'web'
     }
}


module recserviceplan 'modules/web/serverfarm/main.bicep' ={
     name:'serviceplandeploy0001'
     params:{
         name: 'spwebhost'
         location: ubicacion
         sku:{
             name: 'F1'
              tier:'Free'
         }
     }
}


module recsitioweb 'modules/web/site/main.bicep' ={
     name:'sitiowebdeploy0001'
     params:{
         name: 'wstecpruebatotal'
         location: ubicacion
         serverFarmResourceId:recserviceplan.outputs.resourceId
          appInsightResourceId:recappinsight.outputs.applicationId
          kind:'app'
          
     }
}


module recconfigsitioweb 'modules/web/site/config--appsettings/main.bicep' ={
     name:'sitioconfigwebdeploy0001'
     params:{
         appName:recsitioweb.outputs.name
         kind: 'app'
         appInsightResourceId: recappinsight.outputs.resourceId
         enableDefaultTelemetry:true
        appSettingsKeyValuePairs:{
             ApplicationInsightsAgent_EXTENSION_VERSION:'~2'
         }
     }
}
