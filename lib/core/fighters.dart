// Stable roster indices, shared by storage, selection and arena.
const fighterIds = ['luna','kaito','sora','kai','asuka','rex','goro','nova','titan'];
const fighterNames = ['Luna','Kaito','Sora','Kai','Asuka','Rex','Goro','Nova','Titan'];
int validFighter(Object? index) =>
    index is int && index >= 0 && index < fighterIds.length ? index : 0;
