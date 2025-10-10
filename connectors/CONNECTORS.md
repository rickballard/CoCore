# CoSuite Connectors Catalog (Conceptual)

Each connector exposes a capability contract; assets may reference connectors by id.

- CoCache (connector.cocache): artifacts.get/put, receipts.list
- CoRef (connector.coref): refs.search, refs.get
- CoAgent (connector.coagent): blueprint.synthesize, validate.policy, run.simulation
- RegTwin (connector.regtwin): simulate(policy_id, scenario), receipts.get
- MeritRank/RepTag (connector.meritrank): subject.score, org.score
- GIBindex/CoWords (connector.gibindex): term.lookup, term.linked
- Evidence Store (connector.evidence): evidence.get(hash), integrity.verify
- Jurisdiction Overlays (connector.juris): overlay.fetch(code), policy.diff(from,to)
