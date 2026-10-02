$(document).on('shown.bs.modal', function () {
  const confirmButton = document.querySelector(
    '#confirmButton.agent-cross-repo-delete'
  );
  const checkbox = document.getElementById('agentCrossRepoConfirm');

  if (!confirmButton || !checkbox) {
    return;
  }

  confirmButton.disabled = true;
  checkbox.addEventListener('change', function () {
    confirmButton.disabled = !checkbox.checked;
  });
});
