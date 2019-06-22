import { Elm } from '../elm/Main.elm'

document.addEventListener('DOMContentLoaded', function (event) {
  // There is currently no way to prevent default for Browser.Events in Elm. I took the pragmatic approach here to just prevent default
  // on the error keys whose default is problematic due to the fact they might scroll the viewport while playing. This should be replaced as
  // soon as we can prevent default for Browser.Events.
  document.addEventListener('keydown', function (e) {
    if (e.key === 'ArrowDown' || e.key === 'ArrowUp' || e.key === 'ArrowLeft' || e.key === 'ArrowRight') {
      e.preventDefault()
    }
  })

  Elm.Main.init({
    node: document.getElementById('elmboy')
  })
})
