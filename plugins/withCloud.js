const {
  withEntitlementsPlist,
  withInfoPlist,
  createRunOncePlugin,
} = require('@expo/config-plugins');

const withCloudPlugin = (config, options) => {
  const { iCloud } = options;

  if (iCloud) {
    const { kv = {}, documents = [], environment ='Production' } = iCloud;

    config = withEntitlementsPlist(config, async (config) => {
      const e = config.modResults;

      e['com.apple.developer.ubiquity-kvstore-identifier'] = undefined;
      if (kv.enabled) {
        e['com.apple.developer.ubiquity-kvstore-identifier'] =
          '$(TeamIdentifierPrefix)$(CFBundleIdentifier)';
      }

      e['com.apple.developer.icloud-container-identifiers'] = [];
      e['com.apple.developer.icloud-services'] = ['CloudDocuments'];
      e['com.apple.developer.ubiquity-container-identifiers'] = [];
      e['com.apple.developer.icloud-container-environment'] = environment;
      if(documents.length) {
        documents.filter(doc => doc.enabled).map(doc => {
          const id = doc.containerId;
          if(!id) return
          if (!id.startsWith('iCloud')) {
            // https://developer.apple.com/documentation/uikit/documents_data_and_pasteboard/synchronizing_documents_in_the_icloud_environment#:~:text=An%20iCloud%20container%20identifier%20is%20case%2Dsensitive%20and%20must%20begin%20with%20%E2%80%9CiCloud.%E2%80%9D.
            throw new Error("containerId must start with 'iCloud.'");
          }

          e['com.apple.developer.icloud-container-identifiers'].push(id);
          e['com.apple.developer.ubiquity-container-identifiers'].push(id);
        })
      }

      return config;
    });

    config = withInfoPlist(config, async (config) => {
      const e = config.modResults;
      e.NSUbiquitousContainers = {}

      documents.map(doc => {
        const id = doc.containerId;
        if(!id) return
        if(!doc.enabled) return
        if(!doc.visible) return

        const visibleName = doc.visibleName;
        if (!visibleName)
          throw new Error(`you need apply a visibleName for ${id}`);
        e.NSUbiquitousContainers[id] = {
          NSUbiquitousContainerIsDocumentScopePublic: true,
          NSUbiquitousContainerName: visibleName,
          NSUbiquitousContainerSupportedFolderLevels: 'Any',
        };
      })

      return config;
    });
  }

  return config;
};

// should use `createRunOncePlugin` wrap，or `pluginHistory` of output of `expo config --type prebuild`  will not print this plugin
module.exports = createRunOncePlugin(withCloudPlugin, 'with-cloud', '0.0.2');
