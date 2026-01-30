type ErrSansioOrRsvp {
  ErrRsvp(rsvp.Error)
  ErrSansio(r4_sansio.Err)
}

UserTypedName(name) ->
  case name {
    "" -> #(Model(..model, show: EmptyMsg), effect.none())
    name -> {
      let search_req =
        r4_sansio.patient_search_req(
          r4_sansio.SpPatient(
            ..r4_sansio.sp_patient_new(),
            name: Some(name),
          ),
          model.client,
        )
      let handle_read = fn(resp_res: Result(Response(String), rsvp.Error)) {
        ServerReturnedPatients(case resp_res {
          Error(err) -> Error(ErrRsvp(err))
          Ok(resp_res) -> {
            case r4_sansio.any_resp(resp_res, r4.bundle_decoder()) {
              Ok(bundle) ->
                Ok(
                  { bundle |> r4_sansio.bundle_to_groupedresources }.patient,
                )
              Error(err) -> Error(ErrSansio(err))
            }
          }
        })
      }
      let handler = rsvp.expect_any_response(handle_read)
      let search = rsvp.send(search_req, handler)
      let model = Model(..model, show: LoadingMsg)
      #(model, search)
    }
  }

ServerReturnedPatients(Ok(pats)) -> #(
  Model(..model, show: Pats(pats)),
  effect.none(),
)
